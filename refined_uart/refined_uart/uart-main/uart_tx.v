`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/21 21:22:56
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
    parameter CLKS_PER_BIT = 1085, 
    parameter DATA_WIDTH   = 8    
)(
    input  wire clk,
    input  wire reset,
    
    input  wire tx_start,                    
    input  wire [DATA_WIDTH-1:0] tx_data_in, 
    output reg  fifo_read_req,               
    
    // 추가된 하드웨어 핸드셰이크 신호 (PC가 보내주는 RTS 신호와 연결됨)
    input  wire cts_n,                       // 0일 때 PC가 수신 가능함 의미

    output reg  tx_line,
    output reg  tx_busy      
);

    localparam s_IDLE   = 3'b000;
    localparam s_FETCH  = 3'b001; 
    localparam s_LATCH  = 3'b010; 
    localparam s_START  = 3'b011;
    localparam s_DATA   = 3'b100;
    localparam s_PARITY = 3'b101;
    localparam s_STOP   = 3'b110;
    
    reg [2:0]  state;
    reg [15:0] clk_cnt;
    reg [3:0]  bit_idx;
    
    reg [DATA_WIDTH-1:0] tx_data;
    reg                  parity_bit;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= s_IDLE;
            clk_cnt       <= 0;
            bit_idx       <= 0;
            tx_line       <= 1'b1;
            tx_busy       <= 1'b0;
            fifo_read_req <= 1'b0;
            tx_data       <= 0;
            parity_bit    <= 1'b0;
        end else begin
            fifo_read_req <= 1'b0; 
            
            case (state)
                s_IDLE : begin
                    tx_line <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    
                    // 💡 FIFO에 데이터가 있고(tx_start), PC가 준비완료(cts_n == 0) 상태일 때만 전송 시작
                    if (tx_start == 1'b1 && cts_n == 1'b0) begin
                        tx_busy       <= 1'b1;
                        fifo_read_req <= 1'b1; 
                        state         <= s_FETCH;
                    end else begin
                        tx_busy       <= 1'b0;
                    end
                end
                
                s_FETCH : begin
                    state <= s_LATCH;
                end

                s_LATCH : begin
                    tx_data    <= tx_data_in; 
                    parity_bit <= ^tx_data_in;
                    state      <= s_START;
                end
                
                s_START : begin
                    tx_line <= 1'b0;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state   <= s_DATA;
                    end
                end
                
                s_DATA : begin
                    tx_line <= tx_data[bit_idx];
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        if (bit_idx < DATA_WIDTH - 1) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state   <= s_PARITY;
                        end
                    end
                end
                
                s_PARITY : begin
                    tx_line <= parity_bit;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state   <= s_STOP;
                    end
                end
                
                s_STOP : begin
                    tx_line <= 1'b1;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        tx_busy <= 1'b0;
                        state   <= s_IDLE;
                    end
                end
                
                default : state <= s_IDLE;
            endcase
        end
    end
endmodule