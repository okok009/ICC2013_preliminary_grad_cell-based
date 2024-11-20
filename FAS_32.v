// `include "define.v"

module  FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
 fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
 fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0, mid_1, mid_5, mid_9, mid_13);
parameter signed [31:0] w0_real = 32'h00010000;
parameter signed [31:0] w0_imag = 32'h00000000;
parameter signed [31:0] w1_real = 32'h0000EC83;
parameter signed [31:0] w1_imag = 32'hFFFF9E09;
parameter signed [31:0] w2_real = 32'h0000B504;
parameter signed [31:0] w2_imag = 32'hFFFF4AFC;
parameter signed [31:0] w3_real = 32'h000061F7;
parameter signed [31:0] w3_imag = 32'hFFFF137D;
parameter signed [31:0] w4_real = 32'h00000000;
parameter signed [31:0] w4_imag = 32'hFFFF0000;
parameter signed [31:0] w5_real = 32'hFFFF9E09;
parameter signed [31:0] w5_imag = 32'hFFFF137D;
parameter signed [31:0] w6_real = 32'hFFFF4AFC;
parameter signed [31:0] w6_imag = 32'hFFFF4AFC;
parameter signed [31:0] w7_real = 32'hFFFF137D;
parameter signed [31:0] w7_imag = 32'hFFFF9E09;

input clk, rst;
input data_valid;
input [15:0] data; 

output fir_valid, fft_valid;
output [15:0] fir_d;
output [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
output [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
output signed [15:0] mid_1, mid_5, mid_9, mid_13;
output done;
output [3:0] freq;
`include "./dat/FIR_coefficient.dat"

// FIR
wire [35:0] fir_d_cal;

reg signed [(16-1):0] fir_X_reg [0:31];
reg [(17*16-1):0] fir_d_reg;
reg [5:0] count;
integer i;

assign fir_d_cal = (((fir_X_reg[0] + fir_X_reg[31]) * FIR_C00) +
                    ((fir_X_reg[1] + fir_X_reg[30]) * FIR_C01) +
                    ((fir_X_reg[2] + fir_X_reg[29]) * FIR_C02) +
                    ((fir_X_reg[3] + fir_X_reg[28]) * FIR_C03) +
                    ((fir_X_reg[4] + fir_X_reg[27]) * FIR_C04) +
                    ((fir_X_reg[5] + fir_X_reg[26]) * FIR_C05) +
                    ((fir_X_reg[6] + fir_X_reg[25]) * FIR_C06) +
                    ((fir_X_reg[7] + fir_X_reg[24]) * FIR_C07) +
                    ((fir_X_reg[8] + fir_X_reg[23]) * FIR_C08) +
                    ((fir_X_reg[9] + fir_X_reg[22]) * FIR_C09) +
                    ((fir_X_reg[10] + fir_X_reg[21]) * FIR_C10) +
                    ((fir_X_reg[11] + fir_X_reg[20]) * FIR_C11) +
                    ((fir_X_reg[12] + fir_X_reg[19]) * FIR_C12) +
                    ((fir_X_reg[13] + fir_X_reg[18]) * FIR_C13) +
                    ((fir_X_reg[14] + fir_X_reg[17]) * FIR_C14) +
                    ((fir_X_reg[15] + fir_X_reg[16]) * FIR_C15));

// round_36to16 round_FIR(.x(fir_d_cal), .rounded_x(fir_d));
assign fir_d = {fir_d_cal[35], fir_d_cal[30:16]};

assign fir_valid = (count == 6'b100001 || count == 6'b100010) ? 1 : 0;

always @(posedge clk) begin
    if(rst) begin
        for (i=0; i<32; i=i+1) begin
            fir_X_reg[i] <= 16'b0;
        end
        fir_d_reg <= 0;
        count <= 6'b0;
    end
    else if (data_valid) begin
        fir_X_reg[0] <= data;
        for (i=1; i<32; i=i+1) begin
            fir_X_reg[i] <= fir_X_reg[i-1];
        end
        fir_d_reg <= ((count[5] && count[0]) || fir_d_reg[271]) ? {fir_d_reg[254:0], 1'b1, fir_d} : {fir_d_reg[254:0], 1'b0, fir_d};
        if (count != 6'b100010) begin
            count <= count + 1'b1;
        end
    end
end

// FFT
wire fft_valid_valid;
// wire signed [15:0] mid_1, mid_2, mid_3, mid_4, fft_d0_16; // 16 bit only real
wire signed [15:0] fft_d0_16;
wire [31:0] mid_5, mid_6, mid_7, mid_8, mid_9, mid_10, mid_11, mid_12, mid_13, mid_14, mid_15, mid_16; // 32 bit have 16 real 16 imag, so can not use signed

reg fft_valid_reg;
reg fft_valid_valid_reg;
reg signed [15:0] fft_X0_reg, fft_X1_reg, fft_X2_reg, fft_X3_reg, fft_X4_reg, 
                    fft_X5_reg, fft_X6_reg, fft_X7_reg, fft_X8_reg, fft_X9_reg, 
                    fft_X10_reg, fft_X11_reg, fft_X12_reg, fft_X13_reg, fft_X14_reg, fft_X15_reg;

assign fft_valid = fft_valid_reg;
assign fft_valid_valid = fft_valid_valid_reg;
assign fft_d0 = fft_d0_16<<16;

FFT_4point_16_w0_w4 FFT_L_1(fft_X0_reg, fft_X4_reg, fft_X8_reg, fft_X12_reg, mid_1, mid_5, mid_9, mid_13);
FFT_4point_16 #(.w1_real(w1_real), .w1_imag (w1_imag), .w2_real(w5_real), .w2_imag (w5_imag), .w3_real(w2_real), .w3_imag (w2_imag)) FFT_L_2(fft_X1_reg, fft_X5_reg, fft_X9_reg, fft_X13_reg, mid_2, mid_6, mid_10, mid_14);
FFT_4point_16_w4 #(.w1_real(w2_real), .w1_imag (w2_imag), .w2_real(w6_real), .w2_imag (w6_imag)) FFT_L_3(fft_X2_reg, fft_X6_reg, fft_X10_reg, fft_X14_reg, mid_3, mid_7, mid_11, mid_15);
FFT_4point_16 #(.w1_real(w3_real), .w1_imag (w3_imag), .w2_real(w7_real), .w2_imag (w7_imag), .w3_real(w6_real), .w3_imag (w6_imag)) FFT_L_4(fft_X3_reg, fft_X7_reg, fft_X11_reg, fft_X15_reg, mid_4, mid_8, mid_12, mid_16);
FFT_4point_16_w0_w4 FFT_R_1(mid_1, mid_2, mid_3, mid_4, fft_d0_16, fft_d8, fft_d4, fft_d12);
FFT_4point_32 FFT_R_2(mid_5, mid_6, mid_7, mid_8, fft_d2, fft_d10, fft_d6, fft_d14);
FFT_4point_32 FFT_R_3(mid_9, mid_10, mid_11, mid_12, fft_d1, fft_d9, fft_d5, fft_d13);
FFT_4point_32 FFT_R_4(mid_13, mid_14, mid_15, mid_16, fft_d3, fft_d11, fft_d7, fft_d15);

// FFT_seq
always @(posedge clk) begin
    if (rst) begin
        fft_valid_reg <= 1'b0;
        fft_valid_valid_reg <= 1'b0;
        fft_X0_reg <= 16'b0;
        fft_X1_reg <= 16'b0;
        fft_X2_reg <= 16'b0;
        fft_X3_reg <= 16'b0;
        fft_X4_reg <= 16'b0;
        fft_X5_reg <= 16'b0;
        fft_X6_reg <= 16'b0;
        fft_X7_reg <= 16'b0;
        fft_X8_reg <= 16'b0;
        fft_X9_reg <= 16'b0;
        fft_X10_reg <= 16'b0;
        fft_X11_reg <= 16'b0;
        fft_X12_reg <= 16'b0;
        fft_X13_reg <= 16'b0;
        fft_X14_reg <= 16'b0;
        fft_X15_reg <= 16'b0;
    end
    else if (fir_d_reg[271]) begin
        fft_X0_reg <= fir_d_reg[(271-17*0-1) -: 16];
        fft_X1_reg <= fir_d_reg[(271-17*1-1) -: 16];
        fft_X2_reg <= fir_d_reg[(271-17*2-1) -: 16];
        fft_X3_reg <= fir_d_reg[(271-17*3-1) -: 16];
        fft_X4_reg <= fir_d_reg[(271-17*4-1) -: 16];
        fft_X5_reg <= fir_d_reg[(271-17*5-1) -: 16];
        fft_X6_reg <= fir_d_reg[(271-17*6-1) -: 16];
        fft_X7_reg <= fir_d_reg[(271-17*7-1) -: 16];
        fft_X8_reg <= fir_d_reg[(271-17*8-1) -: 16];
        fft_X9_reg <= fir_d_reg[(271-17*9-1) -: 16];
        fft_X10_reg <= fir_d_reg[(271-17*10-1) -: 16];
        fft_X11_reg <= fir_d_reg[(271-17*11-1) -: 16];
        fft_X12_reg <= fir_d_reg[(271-17*12-1) -: 16];
        fft_X13_reg <= fir_d_reg[(271-17*13-1) -: 16];
        fft_X14_reg <= fir_d_reg[(271-17*14-1) -: 16];
        fft_X15_reg <= fir_d_reg[(271-17*15-1) -: 16];
        fft_valid_reg <= 1'b0;
        fft_valid_valid_reg <= 1'b1;
    end
    else if (fft_valid_valid && fir_d_reg[254]) begin
        fft_valid_reg <= 1'b1;
    end
end

// Analysis

reg done;
reg done_buf;
reg start_analysis;
reg signed [15:0] Y0_real;
reg signed [15:0] Y0_imag;
reg signed [15:0] Y1_real;
reg signed [15:0] Y1_imag;
reg signed [15:0] Y2_real;
reg signed [15:0] Y2_imag;
reg signed [15:0] Y3_real;
reg signed [15:0] Y3_imag;
reg signed [15:0] Y4_real;
reg signed [15:0] Y4_imag;
reg signed [15:0] Y5_real;
reg signed [15:0] Y5_imag;
reg signed [15:0] Y6_real;
reg signed [15:0] Y6_imag;
reg signed [15:0] Y7_real;
reg signed [15:0] Y7_imag;
reg signed [15:0] Y8_real;
reg signed [15:0] Y8_imag;
reg signed [15:0] Y9_real;
reg signed [15:0] Y9_imag;
reg signed [15:0] Y10_real;
reg signed [15:0] Y10_imag;
reg signed [15:0] Y11_real;
reg signed [15:0] Y11_imag;
reg signed [15:0] Y12_real;
reg signed [15:0] Y12_imag;
reg signed [15:0] Y13_real;
reg signed [15:0] Y13_imag;
reg signed [15:0] Y14_real;
reg signed [15:0] Y14_imag;
reg signed [15:0] Y15_real;
reg signed [15:0] Y15_imag;

wire signed [31:0] Y0_len;
wire signed [31:0] Y1_len;
wire signed [31:0] Y2_len;
wire signed [31:0] Y3_len;
wire signed [31:0] Y4_len;
wire signed [31:0] Y5_len;
wire signed [31:0] Y6_len;
wire signed [31:0] Y7_len;
wire signed [31:0] Y8_len;
wire signed [31:0] Y9_len;
wire signed [31:0] Y10_len;
wire signed [31:0] Y11_len;
wire signed [31:0] Y12_len;
wire signed [31:0] Y13_len;
wire signed [31:0] Y14_len;
wire signed [31:0] Y15_len;
wire signed [31:0] compare_1_1;
wire signed [31:0] compare_1_2;
wire signed [31:0] compare_1_3;
wire signed [31:0] compare_1_4;
wire signed [31:0] compare_1_5;
wire signed [31:0] compare_1_6;
wire signed [31:0] compare_1_7;
wire signed [31:0] compare_1_8;
wire signed [31:0] compare_2_1;
wire signed [31:0] compare_2_2;
wire signed [31:0] compare_2_3;
wire signed [31:0] compare_2_4;
wire signed [31:0] compare_3_1;
wire signed [31:0] compare_3_2;
wire signed [31:0] compare_4_1;

assign Y0_len = (Y0_real*Y0_real) + (Y0_imag*Y0_imag);
assign Y1_len = (Y1_real*Y1_real) + (Y1_imag*Y1_imag);
assign Y2_len = (Y2_real*Y2_real) + (Y2_imag*Y2_imag);
assign Y3_len = (Y3_real*Y3_real) + (Y3_imag*Y3_imag);
assign Y4_len = (Y4_real*Y4_real) + (Y4_imag*Y4_imag);
assign Y5_len = (Y5_real*Y5_real) + (Y5_imag*Y5_imag);
assign Y6_len = (Y6_real*Y6_real) + (Y6_imag*Y6_imag);
assign Y7_len = (Y7_real*Y7_real) + (Y7_imag*Y7_imag);
assign Y8_len = (Y8_real*Y8_real) + (Y8_imag*Y8_imag);
assign Y9_len = (Y9_real*Y9_real) + (Y9_imag*Y9_imag);
assign Y10_len = (Y10_real*Y10_real) + (Y10_imag*Y10_imag);
assign Y11_len = (Y11_real*Y11_real) + (Y11_imag*Y11_imag);
assign Y12_len = (Y12_real*Y12_real) + (Y12_imag*Y12_imag);
assign Y13_len = (Y13_real*Y13_real) + (Y13_imag*Y13_imag);
assign Y14_len = (Y14_real*Y14_real) + (Y14_imag*Y14_imag);
assign Y15_len = (Y15_real*Y15_real) + (Y15_imag*Y15_imag);

assign compare_1_1 = (Y0_len >= Y1_len) ? Y0_len : Y1_len;
assign compare_1_2 = (Y2_len >= Y3_len) ? Y2_len : Y3_len;
assign compare_1_3 = (Y4_len >= Y5_len) ? Y4_len : Y5_len;
assign compare_1_4 = (Y6_len >= Y7_len) ? Y6_len : Y7_len;
assign compare_1_5 = (Y8_len >= Y9_len) ? Y8_len : Y9_len;
assign compare_1_6 = (Y10_len >= Y11_len) ? Y10_len : Y11_len;
assign compare_1_7 = (Y12_len >= Y13_len) ? Y12_len : Y13_len;
assign compare_1_8 = (Y14_len >= Y15_len) ? Y14_len : Y15_len;
assign compare_2_1 = (compare_1_1 >= compare_1_2) ? compare_1_1 : compare_1_2;
assign compare_2_2 = (compare_1_3 >= compare_1_4) ? compare_1_3 : compare_1_4;
assign compare_2_3 = (compare_1_5 >= compare_1_6) ? compare_1_5 : compare_1_6;
assign compare_2_4 = (compare_1_7 >= compare_1_8) ? compare_1_7 : compare_1_8;
assign compare_3_1 = (compare_2_1 >= compare_2_2) ? compare_2_1 : compare_2_2;
assign compare_3_2 = (compare_2_3 >= compare_2_4) ? compare_2_3 : compare_2_4;
assign compare_4_1 = (compare_3_1 >= compare_3_2) ? compare_3_1 : compare_3_2;

assign freq = (compare_4_1 == Y0_len) ? 4'b0000 :
              (compare_4_1 == Y1_len) ? 4'b0001 :
              (compare_4_1 == Y2_len) ? 4'b0010 :
              (compare_4_1 == Y3_len) ? 4'b0011 :
              (compare_4_1 == Y4_len) ? 4'b0100 :
              (compare_4_1 == Y5_len) ? 4'b0101 :
              (compare_4_1 == Y6_len) ? 4'b0110 :
              (compare_4_1 == Y7_len) ? 4'b0111 :
              (compare_4_1 == Y8_len) ? 4'b1000 :
              (compare_4_1 == Y9_len) ? 4'b1001 :
              (compare_4_1 == Y10_len) ? 4'b1010 :
              (compare_4_1 == Y11_len) ? 4'b1011 :
              (compare_4_1 == Y12_len) ? 4'b1100 :
              (compare_4_1 == Y13_len) ? 4'b1101 :
              (compare_4_1 == Y14_len) ? 4'b1110 :
              (compare_4_1 == Y15_len) ? 4'b1111 : 4'bxxxx;

always @(posedge clk) begin
    if (rst) begin
        done <= 0;
        done_buf <= 0;
        Y0_real <= 0;
        Y0_imag <= 
        Y1_real <= 0;
        Y1_imag <= 
        Y2_real <= 0;
        Y2_imag <= 
        Y3_real <= 0;
        Y3_imag <= 
        Y4_real <= 0;
        Y4_imag <= 
        Y5_real <= 0;
        Y5_imag <= 
        Y6_real <= 0;
        Y6_imag <= 
        Y7_real <= 0;
        Y7_imag <= 
        Y8_real <= 0;
        Y8_imag <= 
        Y9_real <= 0;
        Y9_imag <= 
        Y10_real <= 0;
        Y10_imag <= 0;
        Y11_real <= 0;
        Y11_imag <= 0;
        Y12_real <= 0;
        Y12_imag <= 0;
        Y13_real <= 0;
        Y13_imag <= 0;
        Y14_real <= 0;
        Y14_imag <= 0;
        Y15_real <= 0;
        Y15_imag <= 0;
    end
    else if (done) begin
        done <= 0;
        done_buf <= 0;
    end
    else if (fft_valid_reg) begin
        Y0_real <= fft_d0[31:16];
        Y0_imag <= fft_d0[15:0];
        Y1_real <= fft_d1[31:16];
        Y1_imag <= fft_d1[15:0];
        Y2_real <= fft_d2[31:16];
        Y2_imag <= fft_d2[15:0];
        Y3_real <= fft_d3[31:16];
        Y3_imag <= fft_d3[15:0];
        Y4_real <= fft_d4[31:16];
        Y4_imag <= fft_d4[15:0];
        Y5_real <= fft_d5[31:16];
        Y5_imag <= fft_d5[15:0];
        Y6_real <= fft_d6[31:16];
        Y6_imag <= fft_d6[15:0];
        Y7_real <= fft_d7[31:16];
        Y7_imag <= fft_d7[15:0];
        Y8_real <= fft_d8[31:16];
        Y8_imag <= fft_d8[15:0];
        Y9_real <= fft_d9[31:16];
        Y9_imag <= fft_d9[15:0];
        Y10_real <= fft_d10[31:16];
        Y10_imag <= fft_d10[15:0];
        Y11_real <= fft_d11[31:16];
        Y11_imag <= fft_d11[15:0];
        Y12_real <= fft_d12[31:16];
        Y12_imag <= fft_d12[15:0];
        Y13_real <= fft_d13[31:16];
        Y13_imag <= fft_d13[15:0];
        Y14_real <= fft_d14[31:16];
        Y14_imag <= fft_d14[15:0];
        Y15_real <= fft_d15[31:16];
        Y15_imag <= fft_d15[15:0];
        done_buf <= 1'b1;
    end
    else if (done_buf) begin
        done <= 1'b1;
    end
end

endmodule

module FFT_2point_32_w0(X, Y, fft_a, fft_b);
input [31:0] X;
input [31:0] Y;
output [31:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, b, c, d;
wire signed [15:0] fft_a_real_cal, fft_a_imag_cal;
wire signed [15:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X[31-:16];
assign b = X[15-:16];
assign c = Y[31-:16];
assign d = Y[15-:16];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = a - c;
assign fft_b_imag_cal = b - d;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_32_w4(X, Y, fft_a, fft_b);
input [31:0] X;
input [31:0] Y;
output [31:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, b, c, d;
wire signed [15:0] fft_a_real_cal, fft_a_imag_cal;
wire signed [15:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X[31-:16];
assign b = X[15-:16];
assign c = Y[31-:16];
assign d = Y[15-:16];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = b - d;
assign fft_b_imag_cal = c - a;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_32(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [31:0] X;
input [31:0] Y;
output [31:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, b, c, d;
wire signed [15:0] fft_a_real_cal, fft_a_imag_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;
wire signed [15:0] fft_b_real, fft_b_imag;

round_48to16 roundreal(.x(fft_b_real_cal), .rounded_x(fft_b_real));
round_48to16 roundimag(.x(fft_b_imag_cal), .rounded_x(fft_b_imag));

assign a = X[31-:16];
assign b = X[15-:16];
assign c = Y[31-:16];
assign d = Y[15-:16];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = (a - c) * w_real + (d - b) * w_imag;
assign fft_b_imag_cal = (a - c) * w_imag + (b - d) * w_real;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real, fft_b_imag};
endmodule

module FFT_2point_16_w0(X, Y, fft_a, fft_b);
input [15:0] X;
input [15:0] Y;
output [15:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, c;
wire signed [15:0] fft_a_real_cal;
wire signed [15:0] fft_b_real_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = a - c;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal, 16'b0};
endmodule

module FFT_2point_16_w4(X, Y, fft_a, fft_b);
input [15:0] X;
input [15:0] Y;
output [15:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, c;
wire signed [15:0] fft_a_real_cal;
wire signed [15:0] fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_imag_cal = c - a;

assign fft_a = {fft_a_real_cal};
assign fft_b = {16'b0, fft_b_imag_cal};
endmodule

module FFT_2point_16(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [15:0] X;
input [15:0] Y;
output [15:0] fft_a;
output [31:0] fft_b;

wire signed [15:0] a, c;
wire signed [15:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;
wire signed [15:0] fft_b_real, fft_b_imag;

round_48to16 roundreal(.x(fft_b_real_cal), .rounded_x(fft_b_real));
round_48to16 roundimag(.x(fft_b_imag_cal), .rounded_x(fft_b_imag));

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = (a - c) * w_real;
assign fft_b_imag_cal = (a - c) * w_imag;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real, fft_b_imag};
endmodule

// w1 w3
// w2 w3
module FFT_4point_32(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
input [31:0] in_1, in_2, in_3, in_4;
output [31:0] out_1, out_2, out_3, out_4;

wire [31:0] out_1_1_1, out_1_1_2, out_1_2_1, out_1_2_2;

FFT_2point_32_w0 FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_32_w4 FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_32_w0 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_32_w0 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));

endmodule

module FFT_4point_16_w0_w4(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
input [15:0] in_1, in_2, in_3, in_4;
output [15:0] out_1;
output [31:0] out_2, out_3, out_4;

wire [15:0] out_1_1_1, out_1_2_1;
wire [31:0] out_1_1_2, out_1_2_2;

FFT_2point_16_w0 FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16_w4 FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_16_w0 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_32_w0 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
    
endmodule

module FFT_4point_16_w4(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
input [15:0] in_1, in_2, in_3, in_4;
output [15:0] out_1;
output [31:0] out_2, out_3, out_4;

wire [15:0] out_1_1_1, out_1_2_1;
wire [31:0] out_1_1_2, out_1_2_2;

FFT_2point_16 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_16_w4 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_32_w4 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
    
endmodule

module FFT_4point_16(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
parameter signed [31:0] w3_real = 32'b0;
parameter signed [31:0] w3_imag = 32'b0;
input [15:0] in_1, in_2, in_3, in_4;
output [15:0] out_1;
output [31:0] out_2, out_3, out_4;

wire [15:0] out_1_1_1, out_1_2_1;
wire [31:0] out_1_1_2, out_1_2_2;

FFT_2point_16 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_16 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_32 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
    
endmodule

module round_48to16 (x, rounded_x);
    input [47:0] x;
    output [15:0] rounded_x;

    wire carry_bit;

    assign carry_bit = (x[47]) ? (x[15] && (|x[14:0])) : x[15];
    assign rounded_x = {x[47], (x[30:16] + carry_bit)};

endmodule

module round_36to16 (x, rounded_x);
    input [35:0] x;
    output [15:0] rounded_x;

    wire carry_bit;

    assign carry_bit = (x[35]) ? (x[15] && (|x[14:0])) : x[15];
    assign rounded_x = {x[35], (x[30:16] + carry_bit)};

endmodule