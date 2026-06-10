`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/21 20:42:11
// Design Name: 
// Module Name: FIFO_main
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


module FIFO_main #(
    parameter data_length_in = 8,  // 텀프로젝트 8비트 데이터
    parameter data_length_out = 8, // 출력 8비트로 통일
    parameter register_depth = 8
)(
    input  wire clk1,
    input  wire clk2,
    input  wire [data_length_in-1:0] in_data,
    input  wire reset,
    
    input  wire write_en,
    input  wire read_en, 
    
    output reg  [data_length_out-1:0] out_data,
    
    output wire write_valid, 
    output wire read_valid  
);

    localparam PTR_W = 3; // $clog2(8) = 3
    
    reg [PTR_W:0] write_pointer;
    reg [PTR_W:0] read_pointer;
    
    reg [PTR_W:0] sync1_write_pointer, sync2_write_pointer;
    reg [PTR_W:0] sync1_read_pointer, sync2_read_pointer; 
    
    wire [PTR_W:0] grey_write_pointer;
    wire [PTR_W:0] grey_read_pointer;
    
    wire full;
    wire empty;
    
    localparam MAX_DATA_WIDTH = (data_length_in > data_length_out) ? data_length_in : data_length_out;
    reg [MAX_DATA_WIDTH-1:0] FIFO_REGISTER [register_depth-1:0];
    
    wire data_length_Uppercase = (data_length_in > data_length_out) ? 1'b1 : 1'b0;
    
    assign write_valid = ~full;
    assign read_valid  = ~empty;
    
    assign grey_write_pointer = write_pointer ^ (write_pointer >> 1);
    assign grey_read_pointer  = read_pointer ^ (read_pointer >> 1);
    
    assign full = (grey_write_pointer == { ~sync2_read_pointer[PTR_W:PTR_W-1], sync2_read_pointer[PTR_W-2:0] }); 
    assign empty = (sync2_write_pointer == grey_read_pointer);
    
    // Write Domain (clk1)
    always @(posedge clk1 or posedge reset) begin 
        if (reset) begin
            write_pointer      <= 0;
            sync1_read_pointer <= 0;
            sync2_read_pointer <= 0;        
        end
        else begin
            sync1_read_pointer <= grey_read_pointer;
            sync2_read_pointer <= sync1_read_pointer;
            
            if (!full && write_en) begin
                write_pointer <= write_pointer + 1;
                FIFO_REGISTER[write_pointer[PTR_W-1:0]] <= in_data;
            end
        end
    end
            
    // Read Domain (clk2)
    always @(posedge clk2 or posedge reset) begin 
        if (reset) begin
            out_data            <= 0;        
            read_pointer        <= 0;
            sync1_write_pointer <= 0;
            sync2_write_pointer <= 0;
        end
        else begin
            sync1_write_pointer <= grey_write_pointer;
            sync2_write_pointer <= sync1_write_pointer;
            
            if (!empty && read_en) begin
                read_pointer <= read_pointer + 1;         
                out_data <= FIFO_REGISTER[read_pointer[PTR_W-1:0]][data_length_out - 1 : 0];
            end
        end
    end
    
endmodule