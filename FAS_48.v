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
wire signed [16:0] mid_1, mid_2, mid_3, mid_4, fft_d0_17; // 17 bit only real
wire [95:0] mid_5, mid_6, mid_7, mid_8, mid_9, mid_10, mid_11, mid_12, mid_13, mid_14, mid_15, mid_16; // 96 bit have 16 real 16 imag, so can not use signed
wire [95:0] fft_d1_96, fft_d2_96, fft_d3_96, fft_d4_96, fft_d5_96, fft_d6_96, fft_d7_96,
            fft_d8_96, fft_d9_96, fft_d10_96, fft_d11_96, fft_d12_96, fft_d13_96, fft_d14_96, fft_d15_96;
wire [47:0] fft_d1_r, fft_d2_r, fft_d3_r, fft_d4_r, fft_d5_r, fft_d6_r, fft_d7_r,
            fft_d8_r, fft_d9_r, fft_d10_r, fft_d11_r, fft_d12_r, fft_d13_r, fft_d14_r, fft_d15_r;
wire [47:0] fft_d1_i, fft_d2_i, fft_d3_i, fft_d4_i, fft_d5_i, fft_d6_i, fft_d7_i,
            fft_d8_i, fft_d9_i, fft_d10_i, fft_d11_i, fft_d12_i, fft_d13_i, fft_d14_i, fft_d15_i;

reg fft_valid_reg;
reg fft_valid_valid_reg;
reg signed [15:0] fft_X0_reg, fft_X1_reg, fft_X2_reg, fft_X3_reg, fft_X4_reg, 
                    fft_X5_reg, fft_X6_reg, fft_X7_reg, fft_X8_reg, fft_X9_reg, 
                    fft_X10_reg, fft_X11_reg, fft_X12_reg, fft_X13_reg, fft_X14_reg, fft_X15_reg;

assign fft_valid = fft_valid_reg;
assign fft_valid_valid = fft_valid_valid_reg;
assign fft_d0 = {fft_d0_17[16], fft_d0_17[14:0], 16'b0};

round_96to16 ROUND_r_1(.x(fft_d1_96[95:48]), .rounded_x(fft_d1_r));
round_96to16 ROUND_r_2(.x(fft_d2_96[95:48]), .rounded_x(fft_d2_r));
round_96to16 ROUND_r_3(.x(fft_d3_96[95:48]), .rounded_x(fft_d3_r));
round_96to16 ROUND_r_4(.x(fft_d4_96[95:48]), .rounded_x(fft_d4_r));
round_96to16 ROUND_r_5(.x(fft_d5_96[95:48]), .rounded_x(fft_d5_r));
round_96to16 ROUND_r_6(.x(fft_d6_96[95:48]), .rounded_x(fft_d6_r));
round_96to16 ROUND_r_7(.x(fft_d7_96[95:48]), .rounded_x(fft_d7_r));
round_96to16 ROUND_r_8(.x(fft_d8_96[95:48]), .rounded_x(fft_d8_r));
round_96to16 ROUND_r_9(.x(fft_d9_96[95:48]), .rounded_x(fft_d9_r));
round_96to16 ROUND_r_10(.x(fft_d10_96[95:48]), .rounded_x(fft_d10_r));
round_96to16 ROUND_r_11(.x(fft_d11_96[95:48]), .rounded_x(fft_d11_r));
round_96to16 ROUND_r_12(.x(fft_d12_96[95:48]), .rounded_x(fft_d12_r));
round_96to16 ROUND_r_13(.x(fft_d13_96[95:48]), .rounded_x(fft_d13_r));
round_96to16 ROUND_r_14(.x(fft_d14_96[95:48]), .rounded_x(fft_d14_r));
round_96to16 ROUND_r_15(.x(fft_d15_96[95:48]), .rounded_x(fft_d15_r));

round_96to16 ROUND_i_1(.x(fft_d1_96[47:0]), .rounded_x(fft_d1_i));
round_96to16 ROUND_i_2(.x(fft_d2_96[47:0]), .rounded_x(fft_d2_i));
round_96to16 ROUND_i_3(.x(fft_d3_96[47:0]), .rounded_x(fft_d3_i));
round_96to16 ROUND_i_4(.x(fft_d4_96[47:0]), .rounded_x(fft_d4_i));
round_96to16 ROUND_i_5(.x(fft_d5_96[47:0]), .rounded_x(fft_d5_i));
round_96to16 ROUND_i_6(.x(fft_d6_96[47:0]), .rounded_x(fft_d6_i));
round_96to16 ROUND_i_7(.x(fft_d7_96[47:0]), .rounded_x(fft_d7_i));
round_96to16 ROUND_i_8(.x(fft_d8_96[47:0]), .rounded_x(fft_d8_i));
round_96to16 ROUND_i_9(.x(fft_d9_96[47:0]), .rounded_x(fft_d9_i));
round_96to16 ROUND_i_10(.x(fft_d10_96[47:0]), .rounded_x(fft_d10_i));
round_96to16 ROUND_i_11(.x(fft_d11_96[47:0]), .rounded_x(fft_d11_i));
round_96to16 ROUND_i_12(.x(fft_d12_96[47:0]), .rounded_x(fft_d12_i));
round_96to16 ROUND_i_13(.x(fft_d13_96[47:0]), .rounded_x(fft_d13_i));
round_96to16 ROUND_i_14(.x(fft_d14_96[47:0]), .rounded_x(fft_d14_i));
round_96to16 ROUND_i_15(.x(fft_d15_96[47:0]), .rounded_x(fft_d15_i));

assign fft_d1 = {fft_d1_r, fft_d1_i};
assign fft_d2 = {fft_d2_r, fft_d2_i};
assign fft_d3 = {fft_d3_r, fft_d3_i};
assign fft_d4 = {fft_d4_r, fft_d4_i};
assign fft_d5 = {fft_d5_r, fft_d5_i};
assign fft_d6 = {fft_d6_r, fft_d6_i};
assign fft_d7 = {fft_d7_r, fft_d7_i};
assign fft_d8 = {fft_d8_r, fft_d8_i};
assign fft_d9 = {fft_d9_r, fft_d9_i};
assign fft_d10 = {fft_d10_r, fft_d10_i};
assign fft_d11 = {fft_d11_r, fft_d11_i};
assign fft_d12 = {fft_d12_r, fft_d12_i};
assign fft_d13 = {fft_d13_r, fft_d13_i};
assign fft_d14 = {fft_d14_r, fft_d14_i};
assign fft_d15 = {fft_d15_r, fft_d15_i};



FFT_4point_w0_w4_16 FFT_L_1(fft_X0_reg, fft_X4_reg, fft_X8_reg, fft_X12_reg, mid_1, mid_5, mid_9, mid_13);
FFT_4point_16 #(.w1_real(w1_real), .w1_imag (w1_imag), .w2_real(w5_real), .w2_imag (w5_imag), .w3_real(w2_real), .w3_imag (w2_imag)) FFT_L_2(fft_X1_reg, fft_X5_reg, fft_X9_reg, fft_X13_reg, mid_2, mid_6, mid_10, mid_14);
FFT_4point_w4_16 #(.w1_real(w2_real), .w1_imag (w2_imag), .w2_real(w6_real), .w2_imag (w6_imag)) FFT_L_3(fft_X2_reg, fft_X6_reg, fft_X10_reg, fft_X14_reg, mid_3, mid_7, mid_11, mid_15);
FFT_4point_16 #(.w1_real(w3_real), .w1_imag (w3_imag), .w2_real(w7_real), .w2_imag (w7_imag), .w3_real(w6_real), .w3_imag (w6_imag)) FFT_L_4(fft_X3_reg, fft_X7_reg, fft_X11_reg, fft_X15_reg, mid_4, mid_8, mid_12, mid_16);
FFT_4point_w0_w4_16 FFT_R_1(mid_1, mid_2, mid_3, mid_4, fft_d0_16, fft_d8_96, fft_d4_96, fft_d12_96);
FFT_4point_w0_w4_95 FFT_R_2(mid_5, mid_6, mid_7, mid_8, fft_d2_96, fft_d10_96, fft_d6_96, fft_d14_96);
FFT_4point_w0_w4_95 FFT_R_3(mid_9, mid_10, mid_11, mid_12, fft_d1_96, fft_d9_96, fft_d5_96, fft_d13_96);
FFT_4point_w0_w4_95 FFT_R_4(mid_13, mid_14, mid_15, mid_16, fft_d3_96, fft_d11_96, fft_d7_96, fft_d15_96);

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

module FFT_2point_w0_16_1(X, Y, fft_a, fft_b);
input [15:0] X;
input [15:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [15:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = a - c;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal, 48'b0};
endmodule

module FFT_2point_w4_16_1(X, Y, fft_a, fft_b);
input [15:0] X;
input [15:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [15:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_imag_cal = c - a;

assign fft_a = {fft_a_real_cal};
assign fft_b = {48'b0, fft_b_imag_cal};
endmodule

module FFT_2point_16_1(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [15:0] X;
input [15:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [15:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = (a - c) * w_real;
assign fft_b_imag_cal = (a - c) * w_imag;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_w0_16_2(X, Y, fft_a, fft_b);
input [16:0] X;
input [16:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [16:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = a - c;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal, 48'b0};
endmodule

module FFT_2point_w4_16_2(X, Y, fft_a, fft_b);
input [16:0] X;
input [16:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [16:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_imag_cal = c - a;

assign fft_a = {fft_a_real_cal};
assign fft_b = {48'b0, fft_b_imag_cal};
endmodule

module FFT_2point_16_2(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [16:0] X;
input [16:0] Y;
output [16:0] fft_a;
output [95:0] fft_b;

wire signed [16:0] a, c;
wire signed [16:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X;
assign c = Y;

assign fft_a_real_cal = a + c;

assign fft_b_real_cal = (a - c) * w_real;
assign fft_b_imag_cal = (a - c) * w_imag;

assign fft_a = {fft_a_real_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_w0_95_2(X, Y, fft_a, fft_b);
input [95:0] X;
input [95:0] Y;
output [95:0] fft_a;
output [95:0] fft_b;

wire signed [47:0] a, b, c, d;
wire signed [47:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal;

assign a = X[95:48];
assign b = X[47:0];
assign c = Y[95:48];
assign d = Y[47:0];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = a - c;
assign fft_b_imag_cal = b - d;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_w4_95_2(X, Y, fft_a, fft_b);
input [95:0] X;
input [95:0] Y;
output [95:0] fft_a;
output [95:0] fft_b;

wire signed [47:0] a, c;
wire signed [47:0] fft_a_real_cal;
wire signed [47:0] fft_b_imag_cal;

assign a = X[95:48];
assign b = X[47:0];
assign c = Y[95:48];
assign d = Y[47:0];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = b - d;
assign fft_b_imag_cal = c - a;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_2point_95_2(X, Y, fft_a, fft_b);
parameter signed [31:0] w_real = 0;
parameter signed [31:0] w_imag = 0;
input [95:0] X;
input [95:0] Y;
output [95:0] fft_a;
output [95:0] fft_b;

wire signed [47:0] a, c;
wire signed [47:0] fft_a_real_cal;
wire signed [47:0] fft_b_real_cal, fft_b_imag_cal;

assign a = X[95:48];
assign b = X[47:0];
assign c = Y[95:48];
assign d = Y[47:0];

assign fft_a_real_cal = a + c;
assign fft_a_imag_cal = b + d;

assign fft_b_real_cal = (a - c) * w_real + (d - b) * w_imag;
assign fft_b_imag_cal = (a - c) * w_imag + (b - d) * w_real;

assign fft_a = {fft_a_real_cal, fft_a_imag_cal};
assign fft_b = {fft_b_real_cal, fft_b_imag_cal};
endmodule

module FFT_4point_w0_w4_95(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
input [95:0] in_1, in_2, in_3, in_4;
output [95:0] out_1, out_2, out_3, out_4;

wire [95:0] out_1_1_1, out_1_1_2, out_1_2_1, out_1_2_2;

FFT_2point_w0_95_2 FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_w4_95_2 FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_w0_95_2 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_w0_95_2 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
endmodule

module FFT_4point_w0_w4_16(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
input [15:0] in_1, in_2, in_3, in_4;
output [95:0] out_1, out_2, out_3, out_4;

wire [16:0] out_1_1_1, out_1_2_1;
wire [95:0] out_1_1_2, out_1_2_2;

FFT_2point_w0_16_1 FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_w4_16_1 FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_w0_16_2 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_w0_95_2 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
endmodule

module FFT_4point_w4_16(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
input [15:0] in_1, in_2, in_3, in_4;
output [95:0] out_1, out_2, out_3, out_4;

wire [16:0] out_1_1_1, out_1_2_1;
wire [95:0] out_1_1_2, out_1_2_2;

FFT_2point_16_1 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16_1 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_w4_16_2 FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_w4_95_2 FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
endmodule

module FFT_4point_16(in_1, in_2, in_3, in_4, out_1, out_2, out_3, out_4);
parameter signed [31:0] w1_real = 32'b0;
parameter signed [31:0] w1_imag = 32'b0;  
parameter signed [31:0] w2_real = 32'b0;
parameter signed [31:0] w2_imag = 32'b0;
parameter signed [31:0] w3_real = 32'b0;
parameter signed [31:0] w3_imag = 32'b0;
input [15:0] in_1, in_2, in_3, in_4;
output [95:0] out_1, out_2, out_3, out_4;

wire [16:0] out_1_1_1, out_1_2_1;
wire [95:0] out_1_1_2, out_1_2_2;

FFT_2point_16_1 #(.w_real(w1_real), .w_imag(w1_imag)) FFT_1_1(.X(in_1), .Y(in_3), .fft_a(out_1_1_1), .fft_b(out_1_1_2));
FFT_2point_16_1 #(.w_real(w2_real), .w_imag(w2_imag)) FFT_1_2(.X(in_2), .Y(in_4), .fft_a(out_1_2_1), .fft_b(out_1_2_2));
FFT_2point_16_2 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_1(.X(out_1_1_1), .Y(out_1_2_1), .fft_a(out_1), .fft_b(out_2));
FFT_2point_95_2 #(.w_real(w3_real), .w_imag(w3_imag)) FFT_2_2(.X(out_1_1_2), .Y(out_1_2_2), .fft_a(out_3), .fft_b(out_4));
endmodule

module round_96to16 (x, rounded_x);
    input [95:0] x;
    output [15:0] rounded_x;

    wire carry_bit;

    assign carry_bit = (x[95]) ? (x[15] && (|x[14:0])) : x[15];
    assign rounded_x = {x[95], (x[30:16] + carry_bit)};

endmodule