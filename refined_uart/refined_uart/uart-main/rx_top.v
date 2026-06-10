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
    output wire cmd_error,
    
    // 추가된 하드웨어 핸셰이크 신호 (PC의 CTS 신호와 연결됨)
    output wire rts_n                        // 0이면 수신 가능, 1이면 수신 불가(PC 전송 중지 요청)
);

    wire [7:0] rx_data;
    wire       rx_done;

    wire [7:0] fifo_out_data;
    wire       fifo_read_valid;
    reg        fifo_read_en;

    wire [7:0] plain_data;
    reg        verify_start;
    
    wire       rx_fifo_ready;                // FIFO가 가득 찼는지 판단하기 위한 신호

    // 💡 FIFO가 데이터를 더 쓸 수 없으면(~rx_fifo_ready), RTS를 1로 만들어 PC의 전송을 일시 정지시킴
    assign rts_n = ~rx_fifo_ready;

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

        .write_valid(rx_fifo_ready),         // u_rx_fifo가 full이 아니면 1이 됨
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

    localparam s_IDLE      = 2'b00;
    localparam s_WAIT_DATA = 2'b01; 
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
                        fifo_read_en <= 1'b1; 
                        state        <= s_WAIT_DATA;
                    end
                end

                s_WAIT_DATA: begin
                    state <= s_VERIFY;
                end

                s_VERIFY: begin
                    verify_start <= 1'b1;
                    state        <= s_IDLE; 
                end

                default: state <= s_IDLE;
            endcase
        end
    end

endmodule