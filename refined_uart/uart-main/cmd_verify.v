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
    output reg  [3:0] led
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ve_done   <= 1'b0;
            cmd_error <= 1'b0;
            led       <= 4'b0000;
        end else begin
            ve_done   <= 1'b0; // ve_done은 완료 시점에 1펄스만 발생

            if (verify_start) begin
                case (plain_data)
                    8'b00001111: begin led <= 4'b0001; ve_done <= 1'b1; cmd_error <= 1'b0; end
                    8'b01010101: begin led <= 4'b0010; ve_done <= 1'b1; cmd_error <= 1'b0; end
                    8'b10101010: begin led <= 4'b0011; ve_done <= 1'b1; cmd_error <= 1'b0; end
                    8'b11001100: begin led <= 4'b0100; ve_done <= 1'b1; cmd_error <= 1'b0; end
                    8'b11110000: begin led <= 4'b0101; ve_done <= 1'b1; cmd_error <= 1'b0; end
                    default: begin
                        led       <= 4'b0110;
                        cmd_error <= 1'b1; // 올바르지 않은 명령 처리 시 빨간 LED 상태 유지
                    end
                endcase
            end
        end
    end

endmodule