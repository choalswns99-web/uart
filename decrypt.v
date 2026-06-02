`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/02 15:28:24
// Design Name: 
// Module Name: decrypt
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


module decrypt (
    input  wire [7:0] cipher_text,
    input  wire [3:0] secret_key,
    output wire [7:0] plain_text
);

    wire [3:0] inv_sbox_high;
    wire [3:0] inv_sbox_low;

    wire [7:0] inv_sbox_data;

    inv_sbox u_inv_sbox_high (
        .in_data(cipher_text[7:4]),
        .out_data(inv_sbox_high)
    );

    inv_sbox u_inv_sbox_low (
        .in_data(cipher_text[3:0]),
        .out_data(inv_sbox_low)
    );

    assign inv_sbox_data = {inv_sbox_high, inv_sbox_low};

    assign plain_text = inv_sbox_data ^ {secret_key, secret_key};

endmodule


module inv_sbox (
    input  wire [3:0] in_data,
    output reg  [3:0] out_data
);

    always @(*) begin
        case (in_data)
            4'hC : out_data = 4'h0;
            4'h5 : out_data = 4'h1;
            4'h6 : out_data = 4'h2;
            4'hB : out_data = 4'h3;
            4'h9 : out_data = 4'h4;
            4'h0 : out_data = 4'h5;
            4'hA : out_data = 4'h6;
            4'hD : out_data = 4'h7;
            4'h3 : out_data = 4'h8;
            4'hE : out_data = 4'h9;
            4'hF : out_data = 4'hA;
            4'h8 : out_data = 4'hB;
            4'h4 : out_data = 4'hC;
            4'h7 : out_data = 4'hD;
            4'h1 : out_data = 4'hE;
            4'h2 : out_data = 4'hF;
            default : out_data = 4'h0;
        endcase
    end

endmodule
