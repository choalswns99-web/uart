`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:31:33
// Design Name: 
// Module Name: rx_top
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


module rx_top (
    input  wire clk,
    input  wire reset,

    input  wire rx_line,
    input  wire [3:0] sw,       

    output wire [3:0] led,
    output wire ve_done,
    output wire parity_error,
    output wire cmd_error
);

    wire [7:0] rx_data;
    wire       rx_done;

    wire [7:0] fifo_out_data;
    wire       fifo_read_valid;
    reg        fifo_read_en;

    wire [7:0] plain_data;
    reg        verify_start;

    uart_rx #(
        .CLKS_PER_BIT(1085),
        .DATA_WIDTH(8)
    ) u_uart_rx (
        .clk(clk),
        .reset(reset),
        .rx_line(rx_line),
        .rx_data_out(rx_data),
        .rx_done(rx_done),
        .parity_error(parity_error)
    );

    // 원본 Standard FIFO 그대로 유지
    FIFO_main #(
        .data_length_in(8),
        .data_length_out(8),
        .register_depth(8)
    ) u_rx_fifo (
        .clk1(clk),
        .clk2(clk),
        .reset(reset),

        .write_en(rx_done & ~parity_error),
        .in_data(rx_data),

        .read_en(fifo_read_en),
        .out_data(fifo_out_data),

        .write_valid(),
        .read_valid(fifo_read_valid)
    );

    decrypt u_decrypt (
        .cipher_text(fifo_out_data),
        .secret_key(sw),
        .plain_text(plain_data)
    );

    cmd_verify u_cmd_verify (
        .clk(clk),
        .reset(reset),
        .plain_data(plain_data),
        .verify_start(verify_start),
        .ve_done(ve_done),
        .cmd_error(cmd_error),
        .led(led)
    );

    // --- Standard FIFO 대응 3단계 상태 머신 ---
    localparam s_IDLE      = 2'b00;
    localparam s_WAIT_DATA = 2'b01; // FIFO 데이터 출력 대기 (1클럭)
    localparam s_VERIFY    = 2'b10;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= s_IDLE;
            fifo_read_en <= 1'b0;
            verify_start <= 1'b0;
        end else begin
            fifo_read_en <= 1'b0;
            verify_start <= 1'b0;

            case (state)
                s_IDLE: begin
                    if (fifo_read_valid) begin
                        fifo_read_en <= 1'b1; // 읽기 신호 인가
                        state        <= s_WAIT_DATA;
                    end
                end

                s_WAIT_DATA: begin
                    // 이 엣지에서 FIFO 출력이 바뀜
                    state <= s_VERIFY;
                end

                s_VERIFY: begin
                    // 출력된 데이터를 가지고 검증 트리거 동작
                    verify_start <= 1'b1;
                    state        <= s_IDLE; // 🔄 처리 완료 후 즉시 IDLE로 자동 복귀!
                end

                default: state <= s_IDLE;
            endcase
        end
    end

endmodule