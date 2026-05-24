`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/24 14:19:45
// Design Name: 
// Module Name: tx_fsm
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

module tx_fsm (
    input  wire clk,
    input  wire reset,
    
    input  wire [3:0] sw,
    input  wire btn0,     // 하위 4비트 저장 버튼
    input  wire btn1,     // 상위 4비트 저장 버튼
    input  wire btn2,   // 암호키 설정 버튼
    
    output reg  [7:0] plain_text, // 조립 완성된 8비트 평문
    output reg  [3:0] secret_key, // 저장된 4비트 암호키
    output reg  start_trigger     // FIFO(전송) 발사 신호
);

    reg btn0_d, btn1_d, btn2_d;
    always @(posedge clk) begin
        btn0_d <= btn0; 
        btn1_d <= btn1; 
        btn2_d <= btn2;
    end
    
    wire btn0_rise = btn0 & ~btn0_d;
    wire btn1_rise = btn1 & ~btn1_d;
    wire btn2_rise = btn2 & ~btn2_d;

    localparam s_IDLE      = 2'b00; // 대기
    localparam s_GET_LOWER = 2'b01; // 하위 4비트 저장 완료
    localparam s_GET_UPPER = 2'b10; // 상위 4비트 저장 완료

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= s_IDLE;
            plain_text    <= 8'h00;
            secret_key    <= 4'h0;
            start_trigger <= 1'b0;
        end else begin
            start_trigger <= 1'b0;

            case (state)
                // (IDLE) BTN0이 눌리면 스위치 값을 평문 하위 4비트에 저장
                s_IDLE : begin
                    if (btn0_rise) begin
                        plain_text[3:0] <= sw;
                        state           <= s_GET_LOWER;
                    end
                end
                
                // (GET_LOWER) BTN1이 눌리면 평문 상위 4비트 저장
                s_GET_LOWER : begin
                    if (btn1_rise) begin
                        plain_text[7:4] <= sw;
                        state           <= s_GET_UPPER;
                    end
                end
                
                // (GET_UPPER) BTN2가 눌리면 암호키 저장 + 발사
                s_GET_UPPER : begin
                    if (btn2_rise) begin
                        secret_key    <= sw;
                        start_trigger <= 1'b1;
                        state         <= s_IDLE;
                    end
                end
                
                default : state <= s_IDLE;
            endcase
        end
    end

endmodule