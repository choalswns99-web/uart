`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:51:58
// Design Name: 
// Module Name: tb_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_fifo;

    // --------------------------------------------------
    // 파라미터 설정
    // --------------------------------------------------
    parameter int DATA_W = 12;
    parameter int DEPTH  = 16; // 넉넉하게 16칸으로 설정

    // --------------------------------------------------
    // 테스트용 신호(Signal) 선언
    // --------------------------------------------------
    // Clocks & Reset
    logic clk1 = 0;
    logic clk2 = 0;
    logic reset = 1;

    // Write Interface (clk1 도메인)
    logic write_en;
    logic [DATA_W-1:0] in_data;
    logic write_valid; // FIFO_main의 ~full 신호

    // Read Interface (clk2 도메인)
    logic read_en;
    logic [DATA_W-1:0] out_data;
    logic read_valid;  // FIFO_main의 ~empty 신호

    // --------------------------------------------------
    // 클럭 생성 (2MHz vs 10MHz)
    // --------------------------------------------------
    // 2MHz 클럭 (주기 500ns -> 250ns마다 반전)
    always #250 clk1 = ~clk1; 
    
    // 10MHz 클럭 (주기 100ns -> 50ns마다 반전)
    always #50  clk2 = ~clk2; 

    // --------------------------------------------------
    // 1. ECG 데이터 생성 모듈 (송신부)
    // --------------------------------------------------
    sine_to_fifo #(
        .DATA_WIDTH(DATA_W),
        .X_STRETCH(1)
    ) u_ecg_gen (
        .clk(clk1),
        .reset(reset),
        .fifo_full(~write_valid),     // FIFO가 가득 찼는지 확인 (write_valid가 0이면 full)
        .fifo_write_enable(write_en), // 생성기가 FIFO에 쓰는 신호
        .fifo_data(in_data)
    );

    // --------------------------------------------------
    // 2. 비동기 FIFO 메인 모듈
    // --------------------------------------------------
    FIFO_main #(
        .data_length_in(DATA_W),
        .data_length_out(DATA_W),     // 온전한 파형 확인을 위해 12비트로 통일
        .register_depth(DEPTH)
    ) u_fifo (
        .clk1(clk1),
        .clk2(clk2),
        .in_data(in_data),
        .reset(reset),
        
        .write_en(write_en),
        .read_en(read_en),
        
        .out_data(out_data),
        .write_valid(write_valid),
        .read_valid(read_valid)
    );

    // --------------------------------------------------
    // 3. 수신부 읽기 로직 (clk2 도메인)
    // --------------------------------------------------
    // FIFO에 데이터가 들어있으면(read_valid가 1이면) 무조건 읽어내도록 설정
    // 실제로는 수신 측 상황에 맞게 딜레이를 주거나 제어할 수 있습니다.
    assign read_en = read_valid;

    // --------------------------------------------------
    // 시나리오 제어 및 파형 덤프
    // --------------------------------------------------
    initial begin
        // 시뮬레이터 파형(VCD) 파일 생성
        $dumpfile("fifo_ecg_wave.vcd");
        $dumpvars(0, tb_fifo);

        // 초기 리셋 인가
        reset = 1;
        #1000; 
        
        // 리셋 해제 -> 모듈들 동작 시작
        reset = 0;

        // 128개의 ECG 샘플이 2MHz(500ns 주기)로 모두 생성되고
        // 10MHz로 모두 빠져나오는 것을 보기 위해 충분한 시간 대기
        #100000; 
        
        $display("Simulation Finished.");
        $finish;
    end

endmodule