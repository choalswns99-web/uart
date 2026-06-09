`timescale 1ns / 1ps

module tx_top (
    input  wire clk,              
    input  wire reset,            
    
    input  wire [3:0] sw,         
    input  wire btn0,             
    input  wire btn1,             
    input  wire btn2,             
    
    output wire tx_line,          
    output wire tx_busy           
);

    wire [7:0] plain_text_wire;   
    wire [3:0] secret_key_wire;   
    wire       internal_start;    
    
    wire [7:0] cipher_data;       
    wire [7:0] fifo_out_data;     
    wire       fifo_data_ready;
    wire       uart_read_req;     

    // 1. FSM (버튼 동기화 포함)
    tx_fsm u_fsm (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .btn0(btn0),
        .btn1(btn1),
        .btn2(btn2),
        .plain_text(plain_text_wire), 
        .secret_key(secret_key_wire), 
        .start_trigger(internal_start) 
    );

    // 2. 암호화 (조합 논리)
    encrypt u_encrypt (
        .plain_text(plain_text_wire),
        .secret_key(secret_key_wire),
        .cipher_text(cipher_data)
    );
    

    // 3. TX FIFO (원본 수정 불가 Standard FIFO)
    FIFO_main #(
    .data_length_in(8),
    .data_length_out(8),
    .register_depth(8)
    ) u_tx_fifo (
        .clk1(clk),             
        .clk2(clk),             
        .reset(reset),
        
        .write_en(internal_start),
        .in_data(cipher_data),
        
        .read_en(uart_read_req),
        .out_data(fifo_out_data),
        
        .write_valid(),      
        .read_valid(fifo_data_ready)
    );
    

    // 4. UART 송신단 (Standard FIFO 타이밍 맞춤형)
    uart_tx #(
        .CLKS_PER_BIT(1085), 
        .DATA_WIDTH(8)
    ) u_uart_tx (
        .clk(clk),
        .reset(reset),
        .tx_start(fifo_data_ready),
        .tx_data_in(fifo_out_data),   
        .fifo_read_req(uart_read_req),
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );

endmodule