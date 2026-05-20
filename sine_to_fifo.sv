`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/14 20:43:00
// Design Name: 
// Module Name: sine_to_fifo
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

module sine_to_fifo #(
    parameter int DATA_WIDTH = 12,
    parameter int X_STRETCH = 4 // [핵심] 1개의 데이터를 X축으로 몇 픽셀 늘릴 것인가?
)(
    input  logic clk,
    input  logic reset,
    
    // FIFO Interface
    input  logic fifo_full,
    output logic fifo_write_enable,
    output logic [DATA_WIDTH-1:0] fifo_data
);

    // 128-sample High-Resolution ECG 파형 LUT (12-bit format)
    // 촘촘한 샘플링으로 선형적이고 부드러운 곡선(P, T파)과 예리한 피크(QRS) 제공
    logic [11:0] ecg_lut [0:127] = '{
        // [0~15] Baseline
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        
        // [16~31] P-wave (부드러운 곡선)
        12'd1600, 12'd1632, 12'd1680, 12'd1728, 12'd1776, 12'd1808, 12'd1840, 12'd1840,
        12'd1808, 12'd1776, 12'd1728, 12'd1680, 12'd1632, 12'd1600, 12'd1600, 12'd1600,
        
        // [32~39] PR Segment
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        
        // [40~55] QRS Complex (촘촘하지만 매우 예리한 수직 상승/하강)
        12'd1520, 12'd1360, 12'd1800, 12'd2600, 12'd3300, 12'd3680, 12'd2800, 12'd1600,
        12'd800,  12'd480,  12'd1000, 12'd1400, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        
        // [56~63] ST Segment
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        
        // [64~95] T-wave (길고 완만한 종 모양 곡선)
        12'd1600, 12'd1600, 12'd1616, 12'd1648, 12'd1680, 12'd1728, 12'd1776, 12'd1840,
        12'd1904, 12'd1968, 12'd2016, 12'd2064, 12'd2096, 12'd2112, 12'd2112, 12'd2096,
        12'd2064, 12'd2016, 12'd1968, 12'd1904, 12'd1840, 12'd1776, 12'd1728, 12'd1680,
        12'd1648, 12'd1616, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        
        // [96~127] Baseline & Padding
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600,
        12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600, 12'd1600
    };

    logic [6:0] index;      
    logic [7:0] stretch_cnt; // 늘리기용 카운터

    always_ff @(posedge clk) begin
        if (reset) begin
            index <= '0;
            stretch_cnt <= '0;
            fifo_write_enable <= 1'b0;
            fifo_data <= '0;
        end else begin
            fifo_write_enable <= 1'b0; 

            if (!fifo_full) begin
                fifo_write_enable <= 1'b1;            
                fifo_data <= ecg_lut[index];          

                // [수정된 로직] X_STRETCH 만큼 똑같은 값을 반복해서 쓴 뒤에만 index 증가
                if (stretch_cnt >= X_STRETCH - 1) begin
                    stretch_cnt <= '0;
                    index <= index + 1'b1; 
                end else begin
                    stretch_cnt <= stretch_cnt + 1'b1;
                end
            end
        end
    end

endmodule