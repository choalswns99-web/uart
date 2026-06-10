`timescale 1ns / 1ps

module tx_top (
    input  wire clk,              
    input  wire reset,            
    
    input  wire [3:0] sw,         
    input  wire btn0,             
    input  wire btn1,             
    input  wire btn2,             
    
    output wire tx_line,          
    output wire tx_busy,
    input  wire cts_n            // <-- [수정] PC에서 들어오는 CTS 신호 추가
);

    wire [7:0] plain_text_wire;   
    wire [3:0] secret_key_wire;   
    wire       internal_start;    
    
    wire [7:0] cipher_data;       
    wire [7:0] fifo_out_data;     
    wire       fifo_data_ready;
    wire       uart_read_req;     

    // 1. FSM
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

    // 2. 암호화
    encrypt u_encrypt (
        .plain_text(plain_text_wire),
        .secret_key(secret_key_wire),
        .cipher_text(cipher_data)
    );

    // 3. TX FIFO (8비트 파라미터 적용)
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

    // 4. UART 송신
    uart_tx #(
        .CLKS_PER_BIT(1085), 
        .DATA_WIDTH(8)
    ) u_uart_tx (
        .clk(clk),
        .reset(reset),
        .tx_start(fifo_data_ready),
        .tx_data_in(fifo_out_data),   
        .fifo_read_req(uart_read_req),
        .cts_n(cts_n),               // <-- [수정] 하위 모듈로 CTS 신호 전달
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );

endmodule