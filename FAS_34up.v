// `include "define.v"

module  FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
 fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
 fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);
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
wire signed [15:0] mid_1, mid_2, mid_3, mid_4, fft_d0_16; // 16 bit only real
wire [33:0] mid_5, mid_6, mid_7, mid_8, mid_9, mid_10, mid_11, mid_12, mid_13, mid_14, mid_15, mid_16; // 34 bit have 16 real 16 imag, so can not use signed
wire [33:0] fft_d1_34, fft_d2_34, fft_d3_34, fft_d4_34, fft_d5_34, fft_d6_34, fft_d7_34,
            fft_d8_34, fft_d9_34, fft_d10_34, fft_d11_34, fft_d12_34, fft_d13_34, fft_d14_34, fft_d15_34;

reg fft_valid_reg;
reg fft_valid_valid_reg;
reg signed [16-1:0] fft_X0_reg, fft_X1_reg, fft_X2_reg, fft_X3_reg, fft_X4_reg, 
                    fft_X5_reg, fft_X6_reg, fft_X7_reg, fft_X8_reg, fft_X9_reg, 
                    fft_X10_reg, fft_X11_reg, fft_X12_reg, fft_X13_reg, fft_X14_reg, fft_X15_reg;

assign fft_valid = fft_valid_reg;
assign fft_valid_valid = fft_valid_valid_reg;
assign fft_d0 = fft_d0_16<<16;
assign fft_d1 = {fft_d1_34[33], fft_d1_34[31:17], fft_d1_34[16], fft_d1_34[14:0]};
assign fft_d2 = {fft_d2_34[33], fft_d2_34[31:17], fft_d2_34[16], fft_d2_34[14:0]};
assign fft_d3 = {fft_d3_34[33], fft_d3_34[31:17], fft_d3_34[16], fft_d3_34[14:0]};
assign fft_d4 = {fft_d4_34[33], fft_d4_34[31:17], fft_d4_34[16], fft_d4_34[14:0]};
assign fft_d5 = {fft_d5_34[33], fft_d5_34[31:17], fft_d5_34[16], fft_d5_34[14:0]};
assign fft_d6 = {fft_d6_34[33], fft_d6_34[31:17], fft_d6_34[16], fft_d6_34[14:0]};
assign fft_d7 = {fft_d7_34[33], fft_d7_34[31:17], fft_d7_34[16], fft_d7_34[14:0]};
assign fft_d8 = {fft_d8_34[33], fft_d8_34[31:17], fft_d8_34[16], fft_d8_34[14:0]};
assign fft_d9 = {fft_d9_34[33], fft_d9_34[31:17], fft_d9_34[16], fft_d9_34[14:0]};
assign fft_d10 = {fft_d10_34[33], fft_d10_34[31:17], fft_d10_34[16], fft_d10_34[14:0]};
assign fft_d11 = {fft_d11_34[33], fft_d11_34[31:17], fft_d11_34[16], fft_d11_34[14:0]};
assign fft_d12 = {fft_d12_34[33], fft_d12_34[31:17], fft_d12_34[16], fft_d12_34[14:0]};
assign fft_d13 = {fft_d13_34[33], fft_d13_34[31:17], fft_d13_34[16], fft_d13_34[14:0]};
assign fft_d14 = {fft_d14_34[33], fft_d14_34[31:17], fft_d14_34[16], fft_d14_34[14:0]};
assign fft_d15 = {fft_d15_34[33], fft_d15_34[31:17], fft_d15_34[16], fft_d15_34[14:0]};

FFT_4point_16 #(.w1_real(w0_real) , .w1_imag (w0_imag) , .w2_real(w4_real) , .w2_imag (w4_imag) , .w3_real(w0_real) , .w3_imag (w0_imag)) FFT_L_1(fft_X0_reg , fft_X4_reg , fft_X8_reg , fft_X12_reg , mid_1 , mid_5 , mid_9 , mid_13);
FFT_4point_16 #(.w1_real(w1_real) , .w1_imag (w1_imag) , .w2_real(w5_real) , .w2_imag (w5_imag) , .w3_real(w2_real) , .w3_imag (w2_imag)) FFT_L_2(fft_X1_reg , fft_X5_reg , fft_X9_reg , fft_X13_reg , mid_2 , mid_6 , mid_10 , mid_14);
FFT_4point_16 #(.w1_real(w2_real) , .w1_imag (w2_imag) , .w2_real(w6_real) , .w2_imag (w6_imag) , .w3_real(w4_real) , .w3_imag (w4_imag)) FFT_L_3(fft_X2_reg , fft_X6_reg , fft_X10_reg , fft_X14_reg , mid_3 , mid_7 , mid_11 , mid_15);
FFT_4point_16 #(.w1_real(w3_real) , .w1_imag (w3_imag) , .w2_real(w7_real) , .w2_imag (w7_imag) , .w3_real(w6_real) , .w3_imag (w6_imag)) FFT_L_4(fft_X3_reg , fft_X7_reg , fft_X11_reg , fft_X15_reg , mid_4 , mid_8 , mid_12 , mid_16);
FFT_4point_16 #(.w1_real(w0_real) , .w1_imag (w0_imag) , .w2_real(w4_real) , .w2_imag (w4_imag) , .w3_real(w0_real) , .w3_imag (w0_imag)) FFT_R_1(mid_1 , mid_2 ,mid_3 , mid_4 , fft_d0_16 , fft_d8_34 , fft_d4_34 , fft_d1_342);
FFT_4point_34 #(.w1_real(w0_real) , .w1_imag (w0_imag) , .w2_real(w4_real) , .w2_imag (w4_imag) , .w3_real(w0_real) , .w3_imag (w0_imag)) FFT_R_2(mid_5 , mid_6 ,mid_7 , mid_8 , fft_d2_34 , fft_d10_34 , fft_d6_34 , fft_d14_34);
FFT_4point_34 #(.w1_real(w0_real) , .w1_imag (w0_imag) , .w2_real(w4_real) , .w2_imag (w4_imag) , .w3_real(w0_real) , .w3_imag (w0_imag)) FFT_R_3(mid_9 , mid_10 ,mid_11 , mid_12 , fft_d1_34 , fft_d9_34 , fft_d5_34 , fft_d13_34);
FFT_4point_34 #(.w1_real(w0_real) , .w1_imag (w0_imag) , .w2_real(w4_real) , .w2_imag (w4_imag) , .w3_real(w0_real) , .w3_imag (w0_imag)) FFT_R_4(mid_13 , mid_14 ,mid_15 , mid_16 , fft_d3_34 , fft_d11_34 , fft_d7_34 , fft_d15_34);

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



endmodule

module FFT_2point_34(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [33:0] X;
input [33:0] Y;
output [33:0] fft_a;
output [33:0] fft_b;

wire signed [16:0] a, b, c, d;
wire signed [16:0] fft_a_real_cal, fft_a_imag_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X[33-:17];
assign b = X[16-:17];
assign c = Y[33-:17];
assign d = Y[16-:17];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = (a - c) * w_real + (d - b) * w_imag;
assign fft_b_imag_cal = (a - c) * w_imag + (b - d) * w_real;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal[47], fft_b_real_cal[31:16], fft_b_imag_cal[47], fft_b_imag_cal[31:16]};
endmodule

module FFT_2point_16(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [15:0] X; 
input [15:0] Y;
output [15:0] fft_a;
output [33:0] fft_b;

wire signed [15:0] a, c;
wire signed [15:0] fft_a_real_cal;
wire signed [46:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = (a - c) * w_real;
assign fft_b_imag_cal = (a - c) * w_imag;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal[46], fft_b_real_cal[31:16], fft_b_imag_cal[46], fft_b_imag_cal[31:16]};
endmodule

// w1 w3
// w2 w3
module FFT_4point_34(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
parameter signed [31:0] w3_real = 32'b0;
parameter signed [31:0] w3_imag = 32'b0;
input signed [33:0] in_1, in_2, in_3, in_4;
output signed [33:0] out_1, out_2, out_3, out_4;

wire signed [33:0] out_1_1_1, out_1_1_2, out_1_2_1, out_1_2_2;

FFT_2point_34 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_34 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_34 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_34 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
    
endmodule

module FFT_4point_16(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
parameter signed [31:0] w3_real = 32'b0;
parameter signed [31:0] w3_imag = 32'b0;
input signed [15:0] in_1, in_2, in_3, in_4;
output signed [15:0] out_1;
output signed [33:0] out_2, out_3, out_4;

wire signed [15:0] out_1_1_1, out_1_2_1;
wire signed [33:0] out_1_1_2, out_1_2_2;

FFT_2point_16 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_16 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_34 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
    
endmodule