`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/25 18:54:59
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
    parameter int data_length_in = 12, 
    parameter int data_length_out = 8,
    parameter int register_depth = 8, 
    parameter int input_clk_Mhz = 2, 
    parameter int output_clk_Mhz = 10
)(
    input  logic clk1,
    input  logic clk2,
    input  logic [data_length_in-1:0] in_data,
    input  logic reset,
    
    input  logic write_en,
    input  logic read_en, 
    
    output logic [data_length_out-1:0] out_data,
    
    output logic write_valid, 
    output logic read_valid  
);
    

    localparam int PTR_W = $clog2(register_depth);
    
    logic [PTR_W:0] write_pointer;
    logic [PTR_W:0] read_pointer;
    
    logic [PTR_W:0] sync1_write_pointer, sync2_write_pointer;
    logic [PTR_W:0] sync1_read_pointer, sync2_read_pointer; 
    
    logic [PTR_W:0] grey_write_pointer;
    logic [PTR_W:0] grey_read_pointer;
    
    logic full;
    logic empty;
    
    logic [PTR_W:0] grey_sync_write;
    logic [PTR_W:0] grey_sync_read;
    
    logic rst_clk1_ff1, rst_clk1_ff2;
    logic rst_clk2_ff1, rst_clk2_ff2;
    
    localparam int MAX_DATA_WIDTH = (data_length_in > data_length_out) ? data_length_in : data_length_out;
    logic [MAX_DATA_WIDTH-1:0] FIFO_REGISTER [register_depth-1:0];
    
    logic data_length_Uppercase = (data_length_in > data_length_out) ? 1'b1 : 1'b0;
    
    assign write_valid = ~full;
    assign read_valid  = ~empty;
    
    assign grey_write_pointer = write_pointer ^ (write_pointer >> 1);
    assign grey_read_pointer  = read_pointer ^ (read_pointer >> 1);
    
    assign full = (grey_write_pointer == { ~sync2_read_pointer[PTR_W:PTR_W-1], sync2_read_pointer[PTR_W-2:0] }); 
    assign empty = (sync2_write_pointer == grey_read_pointer);
    
    always_ff @(posedge clk1) begin 
        if (reset) begin
            rst_clk1_ff1 <= 1'b1;
            rst_clk1_ff2 <= 1'b1;
        end else begin
            rst_clk1_ff1 <= 1'b0;
            rst_clk1_ff2 <= rst_clk1_ff1;
        end
    end
    
    always_ff @(posedge clk1) begin 
        if (rst_clk1_ff2) begin
            write_pointer      <= 'b0;
            sync1_read_pointer <= 'b0;
            sync2_read_pointer <= 'b0;        
        end
        else begin
            sync1_read_pointer <= grey_sync_read;
            sync2_read_pointer <= sync1_read_pointer;
            grey_sync_write <= grey_write_pointer;
            if (!full && write_en) begin
                write_pointer <= write_pointer + 1'b1;
                FIFO_REGISTER[write_pointer[PTR_W-1:0]][data_length_in-1:0] <= in_data;
            end
        end
    end
            

    always_ff @(posedge clk2 or posedge reset) begin 
        if (reset) begin
            rst_clk2_ff1 <= 1'b1;
            rst_clk2_ff2 <= 1'b1;
        end else begin
            rst_clk2_ff1 <= 1'b0;
            rst_clk2_ff2 <= rst_clk2_ff1;
        end
    end
    
    always_ff @(posedge clk2 or posedge reset) begin 
        if (rst_clk2_ff2) begin
            out_data            <= 'b0;        
            read_pointer        <= 'b0;
            sync1_write_pointer <= 'b0;
            sync2_write_pointer <= 'b0;
        end
        else begin
            sync1_write_pointer <= grey_sync_write;
            sync2_write_pointer <= sync1_write_pointer;
            grey_sync_read <= grey_read_pointer;
            
            if (!empty && read_en) begin
                read_pointer <= read_pointer + 1'b1;         
                if (data_length_Uppercase) begin
                    out_data <= FIFO_REGISTER[read_pointer[PTR_W-1:0]][data_length_in - 1 : data_length_in - data_length_out];
                end else begin
                    out_data <= FIFO_REGISTER[read_pointer[PTR_W-1:0]][data_length_out - 1 : 0];
                end
            end
        end
    end
    
endmodule
