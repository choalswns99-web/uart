`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/08 11:58:49
// Design Name: 
// Module Name: UART
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


module UART(
    input  logic reset,
    input  logic clk,
    input  logic butten0,
    input  logic butten1,
    input  logic butten2,
    
    input  logic switch0,
    input  logic switch1,
    input  logic switch2,
    input  logic switch3,
    
    output logic [3:0] Led,
    
    output logic led5_r,
    output logic led5_g,
    output logic led5_b,

    output logic led6_r,
    output logic led6_g,
    output logic led6_b
);
    
    logic transaction_line;
    logic [3:0] sec_key;
    logic busy_sign;
    

    logic ve_done_sig;
    logic parity_error_sig;
    logic cmd_error_sig;

    assign sec_key = {switch3, switch2, switch1, switch0};
    
    assign led5_r = parity_error_sig;
    assign led5_g = ~parity_error_sig;
    assign led5_b = 1'b0;
    

    assign led6_r = cmd_error_sig;
    assign led6_g = ~cmd_error_sig;
    assign led6_b = 1'b0; 

    tx_top UART_tx_top(
        .clk(clk),              
        .reset(reset),
        
        .sw(sec_key),         
        .btn0(butten0),              
        .btn1(butten1),              
        .btn2(butten2),              
        
        .tx_line(transaction_line),          
        .tx_busy(busy_sign)
    );
    
    rx_top UART_rx_top (
        .clk(clk),
        .reset(reset),

        .rx_line(transaction_line),
        .sw(sec_key),

        .led(Led),
        
        // 내부 신호 연결
        .ve_done(ve_done_sig),
        .parity_error(parity_error_sig),
        .cmd_error(cmd_error_sig)
    );
    
endmodule
