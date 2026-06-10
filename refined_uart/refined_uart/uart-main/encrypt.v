`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/21 21:23:26
// Design Name: 
// Module Name: encrypt
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

module encrypt (
    input  wire [7:0] plain_text,  // 8비트 평문 데이터 (버튼으로 입력받은 값)
    input  wire [3:0] secret_key,  // 4비트 암호 키 (Zybo 보드 스위치 값)
    output wire [7:0] cipher_text  // 완성된 8비트 암호문 출력
);

    // 1단계: XOR
    wire [7:0] xored_data;
    assign xored_data = plain_text ^ {secret_key, secret_key};

    // 2단계: S-Box 비선형 치환
    wire [3:0] sbox_out_high;  //상위 4비트
    wire [3:0] sbox_out_low;  // 하위 4비트

    // 상위 4비트 치환
    sbox u_sbox_high (
        .in_data(xored_data[7:4]), 
        .out_data(sbox_out_high)
    );
    
    // 하위 4비트 치환
    sbox u_sbox_low (
        .in_data(xored_data[3:0]), 
        .out_data(sbox_out_low)
    );

    assign cipher_text = {sbox_out_high, sbox_out_low};

endmodule

// 4비트 S-Box (Look-Up Table)
module sbox (
    input  wire [3:0] in_data,
    output reg  [3:0] out_data
);
    //  PRESENT S-Box 규격 적용
    always @(*) begin
        case (in_data)
            4'h0 : out_data = 4'hC;
            4'h1 : out_data = 4'h5;
            4'h2 : out_data = 4'h6;
            4'h3 : out_data = 4'hB;
            4'h4 : out_data = 4'h9;
            4'h5 : out_data = 4'h0;
            4'h6 : out_data = 4'hA;
            4'h7 : out_data = 4'hD;
            4'h8 : out_data = 4'h3;
            4'h9 : out_data = 4'hE;
            4'hA : out_data = 4'hF;
            4'hB : out_data = 4'h8;
            4'hC : out_data = 4'h4;
            4'hD : out_data = 4'h7;
            4'hE : out_data = 4'h1;
            4'hF : out_data = 4'h2;
            default : out_data = 4'h0;
        endcase
    end
endmodule
