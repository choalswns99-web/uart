`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:39:47
// Design Name: 
// Module Name: tb_rx_top
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



module tb_rx_top;

    reg clk;
    reg reset;
    reg rx_line;
    reg [3:0] sw;

    wire [4:0] led;
    wire ve_done;
    wire parity_error;
    wire cmd_error;

    localparam CLKS_PER_BIT = 1085;
    localparam CLK_PERIOD   = 10;

    rx_top DUT (
        .clk(clk),
        .reset(reset),
        .rx_line(rx_line),
        .sw(sw),
        .led(led),
        .ve_done(ve_done),
        .parity_error(parity_error),
        .cmd_error(cmd_error)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    task UART_SEND;
        input [7:0] data;
        integer i;
        reg parity;
        begin
            parity = ^data;

            rx_line = 1'b0;
            #(CLKS_PER_BIT * CLK_PERIOD);

            for (i = 0; i < 8; i = i + 1) begin
                rx_line = data[i];
                #(CLKS_PER_BIT * CLK_PERIOD);
            end

            rx_line = parity;
            #(CLKS_PER_BIT * CLK_PERIOD);

            rx_line = 1'b1;
            #(CLKS_PER_BIT * CLK_PERIOD);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        rx_line = 1;
        sw = 4'hA;   

        #100;
        reset = 0;

        UART_SEND(8'h66);

        #(CLKS_PER_BIT * CLK_PERIOD * 5);

       
        UART_SEND(8'h22);

        #(CLKS_PER_BIT * CLK_PERIOD * 5);

        $stop;
    end

endmodule