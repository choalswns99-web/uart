`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:29:59
// Design Name: 
// Module Name: uart_rx
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

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 1085,
    parameter DATA_WIDTH   = 8
)(
    input  wire clk,
    input  wire reset,

    input  wire rx_line,

    output reg  [DATA_WIDTH-1:0] rx_data_out,
    output reg  rx_done,
    output reg  parity_error
);

    localparam s_IDLE   = 3'b000;
    localparam s_START  = 3'b001;
    localparam s_DATA   = 3'b010;
    localparam s_PARITY = 3'b011;
    localparam s_STOP   = 3'b100;
    localparam s_CLEAN  = 3'b101;

    reg [2:0] state;
    reg [15:0] clk_cnt;
    reg [3:0] bit_idx;

    reg [DATA_WIDTH-1:0] rx_data;
    reg received_parity;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= s_IDLE;
            clk_cnt         <= 0;
            bit_idx         <= 0;
            rx_data         <= 0;
            rx_data_out     <= 0;
            received_parity <= 0;
            rx_done         <= 0;
            parity_error    <= 0;
        end else begin
            rx_done <= 1'b0;

            case (state)

                s_IDLE: begin
                    clk_cnt      <= 0;
                    bit_idx      <= 0;
                    parity_error <= 1'b0;

                    if (rx_line == 1'b0)
                        state <= s_START;
                end

                s_START: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_line == 1'b0) begin
                            clk_cnt <= 0;
                            state   <= s_DATA;
                        end else begin
                            state <= s_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                s_DATA: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        rx_data[bit_idx] <= rx_line;

                        if (bit_idx < DATA_WIDTH - 1)
                            bit_idx <= bit_idx + 1;
                        else begin
                            bit_idx <= 0;
                            state   <= s_PARITY;
                        end
                    end
                end

                s_PARITY: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        received_parity <= rx_line;
                        state <= s_STOP;
                    end
                end

                s_STOP: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;

                        if (rx_line == 1'b1) begin
                            rx_data_out  <= rx_data;
                            parity_error <= (received_parity != (^rx_data));
                        end else begin
                            parity_error <= 1'b1;
                        end

                        state <= s_CLEAN;
                    end
                end

                s_CLEAN: begin
                    rx_done <= 1'b1;
                    state   <= s_IDLE;
                end

                default: state <= s_IDLE;

            endcase
        end
    end

endmodule
