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
    input  wire btn0,     
    input  wire btn1,     
    input  wire btn2,   
    
    output reg  [7:0] plain_text, 
    output reg  [3:0] secret_key, 
    output reg  start_trigger     
);

    // 물리 버튼 오작동 방지 (2-Stage Synchronizer)
    reg btn0_sync1, btn0_sync2, btn0_d;
    reg btn1_sync1, btn1_sync2, btn1_d;
    reg btn2_sync1, btn2_sync2, btn2_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btn0_sync1 <= 0; btn0_sync2 <= 0; btn0_d <= 0;
            btn1_sync1 <= 0; btn1_sync2 <= 0; btn1_d <= 0;
            btn2_sync1 <= 0; btn2_sync2 <= 0; btn2_d <= 0;
        end else begin
            btn0_sync1 <= btn0; btn0_sync2 <= btn0_sync1; btn0_d <= btn0_sync2;
            btn1_sync1 <= btn1; btn1_sync2 <= btn1_sync1; btn1_d <= btn1_sync2;
            btn2_sync1 <= btn2; btn2_sync2 <= btn2_sync1; btn2_d <= btn2_sync2;
        end
    end
    
    wire btn0_rise = btn0_sync2 & ~btn0_d;
    wire btn1_rise = btn1_sync2 & ~btn1_d;
    wire btn2_rise = btn2_sync2 & ~btn2_d;

    localparam s_IDLE      = 2'b00; 
    localparam s_GET_LOWER = 2'b01; 
    localparam s_GET_UPPER = 2'b10; 

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= s_IDLE;
            plain_text    <= 8'h00;
            secret_key    <= 4'h0;
            start_trigger <= 1'b0;
        end else begin
            start_trigger <= 1'b0; // 기본적으로 펄스는 0 유지

            case (state)
                s_IDLE : begin
                    if (btn0_rise) begin
                        plain_text[3:0] <= sw;
                        state           <= s_GET_LOWER;
                    end
                end
                
                s_GET_LOWER : begin
                    if (btn1_rise) begin
                        plain_text[7:4] <= sw;
                        state           <= s_GET_UPPER;
                    end
                end
                
                s_GET_UPPER : begin
                    if (btn2_rise) begin
                        secret_key    <= sw;
                        start_trigger <= 1'b1; // UART 전송 시작 트리거
                        state         <= s_IDLE;
                    end
                end
                
                default : state <= s_IDLE;
            endcase
        end
    end
endmodule