`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:30:56
// Design Name: 
// Module Name: cmd_verify
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


module cmd_verify (
    input  wire clk,
    input  wire reset,

    input  wire [7:0] plain_data,
    input  wire verify_start,

    output reg  ve_done,
    output reg  cmd_error,
    output reg  [4:0] led
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ve_done   <= 1'b0;
            cmd_error <= 1'b0;
            led       <= 5'b00000;
        end else begin
            ve_done   <= 1'b0;
            cmd_error <= 1'b0;

            if (verify_start) begin
                case (plain_data)
                    8'b00001111: begin
                        led     <= 5'b00001; // 전진
                        ve_done <= 1'b1;
                    end

                    8'b01010101: begin
                        led     <= 5'b00010; // 후진
                        ve_done <= 1'b1;
                    end

                    8'b10101010: begin
                        led     <= 5'b00100; // 정지
                        ve_done <= 1'b1;
                    end

                    8'b11001100: begin
                        led     <= 5'b01000; // 상승
                        ve_done <= 1'b1;
                    end

                    8'b11110000: begin
                        led     <= 5'b10000; // 하강
                        ve_done <= 1'b1;
                    end

                    default: begin
                        led       <= 5'b00000;
                        cmd_error <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule