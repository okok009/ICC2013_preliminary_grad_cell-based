`include "define.v"

module  FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
 fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
 fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);

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
wire [`FIR_CAL_OUT_BW -1:0] fir_d_cal;

reg signed [`BW -1:0] fir_X_reg [0:31];
reg [`BW*17 -1:0] fir_d_reg; // 17: beacause we use 1 bit to label which one element of new FFT input is the first
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

round_FIR_CAL_OUT_BW_16 round_FIR(.x(fir_d_cal), .rounded_x(fir_d));

// assign fir_valid = (count == 6'b100001 || count == 6'b100010) ? 1 : 0; // old version
assign fir_valid = (count[5] && (count[0] || count[1])) ? 1 : 0;

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
        // fir_d_reg <= ((count[5] && count[0]) || fir_d_reg[`BW*17 -1]) ? {fir_d_reg[`BW*17-17 -1:0], 1'b1, fir_d} : {fir_d_reg[`BW*17-17 -1:0], 1'b0, fir_d}; // old version
        fir_d_reg <= {fir_d_reg[`BW*17-17 -1:0], ((count[5] && count[0]) || fir_d_reg[`BW*17 -1]), fir_d};
        // if (count != 6'b100010) begin // old version
        if (~(count[5]&&count[1])) begin
            count <= count + 1'b1;
        end
    end
end

// FFT
wire fft_valid_valid;
wire signed [`FFT_OUT_L_UP_BW -1:0] mid_1, mid_2, mid_3, mid_4;
wire signed [`FFT_OUT_L_DOWN_BW*2 -1:0] mid_5, mid_6, mid_7, mid_8, mid_9, mid_10, mid_11, mid_12, mid_13, mid_14, mid_15, mid_16;
wire [`FFT_OUT_R_UP_BW -1:0]        fft_d0_out;
wire [`FFT_OUT_R_UP_BW*2 -1:0]      fft_d8_out, fft_d4_out, fft_d12_out;
wire [`FFT_OUT_R_DOWN_BW*2 -1:0]    fft_d1_out, fft_d5_out, fft_d6_out, fft_d7_out, fft_d2_out, fft_d9_out,
                                    fft_d10_out, fft_d11_out, fft_d3_out, fft_d13_out, fft_d14_out, fft_d15_out;
wire [`BW -1:0] fft_d0_r, fft_d1_r, fft_d2_r, fft_d3_r, fft_d4_r, fft_d5_r, fft_d6_r, fft_d7_r,
                fft_d8_r, fft_d9_r, fft_d10_r, fft_d11_r, fft_d12_r, fft_d13_r, fft_d14_r, fft_d15_r;
wire [`BW -1:0] fft_d1_i, fft_d2_i, fft_d3_i, fft_d4_i, fft_d5_i, fft_d6_i, fft_d7_i,
                fft_d8_i, fft_d9_i, fft_d10_i, fft_d11_i, fft_d12_i, fft_d13_i, fft_d14_i, fft_d15_i;

reg fft_valid_reg;
reg fft_valid_valid_reg;
reg signed [`BW -1:0]   fft_X0_reg, fft_X1_reg, fft_X2_reg, fft_X3_reg, fft_X4_reg, 
                        fft_X5_reg, fft_X6_reg, fft_X7_reg, fft_X8_reg, fft_X9_reg, 
                        fft_X10_reg, fft_X11_reg, fft_X12_reg, fft_X13_reg, fft_X14_reg, fft_X15_reg;

// FFT_body
FFT_4points_L_0 fft4pL0(.a(fft_X0_reg), .b(fft_X4_reg), .c(fft_X8_reg), .d(fft_X12_reg), .o1(mid_1), .o2(mid_5), .o3(mid_9), .o4(mid_13));
FFT_4points_L_1 fft4pL1(.a(fft_X1_reg), .b(fft_X5_reg), .c(fft_X9_reg), .d(fft_X13_reg), .o1(mid_2), .o2(mid_6), .o3(mid_10), .o4(mid_14));
FFT_4points_L_2 fft4pL2(.a(fft_X2_reg), .b(fft_X6_reg), .c(fft_X10_reg), .d(fft_X14_reg), .o1(mid_3), .o2(mid_7), .o3(mid_11), .o4(mid_15));
FFT_4points_L_3 fft4pL3(.a(fft_X3_reg), .b(fft_X7_reg), .c(fft_X11_reg), .d(fft_X15_reg), .o1(mid_4), .o2(mid_8), .o3(mid_12), .o4(mid_16));
FFT_4points_R_0 fft4pR0(.a(mid_1), .b(mid_2), .c(mid_3), .d(mid_4), .o1(fft_d0_out), .o2(fft_d8_out), .o3(fft_d4_out), .o4(fft_d12_out));
FFT_4points_R_1 fft4pR1(.a(mid_5), .b(mid_6), .c(mid_7), .d(mid_8), .o1(fft_d2_out), .o2(fft_d10_out), .o3(fft_d6_out), .o4(fft_d14_out));
FFT_4points_R_2 fft4pR2(.a(mid_9), .b(mid_10), .c(mid_11), .d(mid_12), .o1(fft_d1_out), .o2(fft_d9_out), .o3(fft_d5_out), .o4(fft_d13_out));
FFT_4points_R_3 fft4pR3(.a(mid_13), .b(mid_14), .c(mid_15), .d(mid_16), .o1(fft_d3_out), .o2(fft_d11_out), .o3(fft_d7_out), .o4(fft_d15_out));

// // round real
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_1(.x(fft_d1_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d1_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_2(.x(fft_d2_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d2_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_3(.x(fft_d3_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d3_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_5(.x(fft_d5_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d5_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_6(.x(fft_d6_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d6_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_7(.x(fft_d7_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d7_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_9(.x(fft_d9_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d9_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_10(.x(fft_d10_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d10_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_11(.x(fft_d11_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d11_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_13(.x(fft_d13_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d13_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_14(.x(fft_d14_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d14_r));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_r_15(.x(fft_d15_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d15_r));

// // round imag
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_1(.x(fft_d1_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d1_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_2(.x(fft_d2_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d2_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_3(.x(fft_d3_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d3_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_5(.x(fft_d5_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d5_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_6(.x(fft_d6_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d6_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_7(.x(fft_d7_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d7_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_9(.x(fft_d9_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d9_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_10(.x(fft_d10_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d10_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_11(.x(fft_d11_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d11_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_13(.x(fft_d13_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d13_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_14(.x(fft_d14_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d14_i));
from_FFT_OUT_R_DOWN_BW_to_BW ROUND_i_15(.x(fft_d15_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d15_i));

assign fft_d0 = {fft_d0_out[`FFT_OUT_R_UP_BW-1], fft_d0_out[`BW -2:0], `BW'b0};
assign fft_d1 = {fft_d1_r, fft_d1_i};
assign fft_d2 = {fft_d2_r, fft_d2_i};
assign fft_d3 = {fft_d3_r, fft_d3_i};
assign fft_d4 = {fft_d4_out[`FFT_OUT_R_UP_BW*2-1], fft_d4_out[`BW + `FFT_OUT_R_UP_BW -2:`FFT_OUT_R_UP_BW], fft_d4_out[`FFT_OUT_R_UP_BW-1], fft_d4_out[`BW -2:0]};
assign fft_d5 = {fft_d5_r, fft_d5_i};
assign fft_d6 = {fft_d6_r, fft_d6_i};
assign fft_d7 = {fft_d7_r, fft_d7_i};
assign fft_d8 = {fft_d8_out[`FFT_OUT_R_UP_BW*2-1], fft_d8_out[`BW + `FFT_OUT_R_UP_BW -2:`FFT_OUT_R_UP_BW], fft_d8_out[`FFT_OUT_R_UP_BW-1], fft_d8_out[`BW -2:0]};
assign fft_d9 = {fft_d9_r, fft_d9_i};
assign fft_d10 = {fft_d10_r, fft_d10_i};
assign fft_d11 = {fft_d11_r, fft_d11_i};
assign fft_d12 = {fft_d12_out[`FFT_OUT_R_UP_BW*2-1], fft_d12_out[`BW + `FFT_OUT_R_UP_BW -2:`FFT_OUT_R_UP_BW], fft_d12_out[`FFT_OUT_R_UP_BW-1], fft_d12_out[`BW -2:0]};
assign fft_d13 = {fft_d13_r, fft_d13_i};
assign fft_d14 = {fft_d14_r, fft_d14_i};
assign fft_d15 = {fft_d15_r, fft_d15_i};

// FFT_valid
assign fft_valid = fft_valid_reg;
assign fft_valid_valid = fft_valid_valid_reg;

always @(posedge clk) begin
    if (rst) begin
        fft_valid_reg <= 1'b0;
        fft_valid_valid_reg <= 1'b0;
        fft_X0_reg <= `BW'b0;
        fft_X1_reg <= `BW'b0;
        fft_X2_reg <= `BW'b0;
        fft_X3_reg <= `BW'b0;
        fft_X4_reg <= `BW'b0;
        fft_X5_reg <= `BW'b0;
        fft_X6_reg <= `BW'b0;
        fft_X7_reg <= `BW'b0;
        fft_X8_reg <= `BW'b0;
        fft_X9_reg <= `BW'b0;
        fft_X10_reg <= `BW'b0;
        fft_X11_reg <= `BW'b0;
        fft_X12_reg <= `BW'b0;
        fft_X13_reg <= `BW'b0;
        fft_X14_reg <= `BW'b0;
        fft_X15_reg <= `BW'b0;
    end
    else if (fir_d_reg[`BW*17 -1]) begin // if the fir_d_reg are whole new signal (the LHS is label 1)
        fft_X0_reg <= fir_d_reg[((`BW*17 -1)-17*0-1) -: `BW]; // -1 beacaue the first bit of each 17 bit element is label
        fft_X1_reg <= fir_d_reg[((`BW*17 -1)-17*1-1) -: `BW];
        fft_X2_reg <= fir_d_reg[((`BW*17 -1)-17*2-1) -: `BW];
        fft_X3_reg <= fir_d_reg[((`BW*17 -1)-17*3-1) -: `BW];
        fft_X4_reg <= fir_d_reg[((`BW*17 -1)-17*4-1) -: `BW];
        fft_X5_reg <= fir_d_reg[((`BW*17 -1)-17*5-1) -: `BW];
        fft_X6_reg <= fir_d_reg[((`BW*17 -1)-17*6-1) -: `BW];
        fft_X7_reg <= fir_d_reg[((`BW*17 -1)-17*7-1) -: `BW];
        fft_X8_reg <= fir_d_reg[((`BW*17 -1)-17*8-1) -: `BW];
        fft_X9_reg <= fir_d_reg[((`BW*17 -1)-17*9-1) -: `BW];
        fft_X10_reg <= fir_d_reg[((`BW*17 -1)-17*10-1) -: `BW];
        fft_X11_reg <= fir_d_reg[((`BW*17 -1)-17*11-1) -: `BW];
        fft_X12_reg <= fir_d_reg[((`BW*17 -1)-17*12-1) -: `BW];
        fft_X13_reg <= fir_d_reg[((`BW*17 -1)-17*13-1) -: `BW];
        fft_X14_reg <= fir_d_reg[((`BW*17 -1)-17*14-1) -: `BW];
        fft_X15_reg <= fir_d_reg[((`BW*17 -1)-17*15-1) -: `BW];
        fft_valid_reg <= 1'b0;
        fft_valid_valid_reg <= 1'b1;
    end
    else if (fft_valid_valid && fir_d_reg[`BW*17-17 -1]) begin  // after the first input come (fft_valid_valid) & before the new inputs come (fir_d_reg[`BW*17-17 -1]) 
        fft_valid_reg <= 1'b1;
    end
end

// Analysis

reg done;
reg done_buf;
reg start_analysis;
reg signed [`ANALYSIS_BW -1:0] Y0_real;
reg signed [`ANALYSIS_BW -1:0] Y0_imag;
reg signed [`ANALYSIS_BW -1:0] Y1_real;
reg signed [`ANALYSIS_BW -1:0] Y1_imag;
reg signed [`ANALYSIS_BW -1:0] Y2_real;
reg signed [`ANALYSIS_BW -1:0] Y2_imag;
reg signed [`ANALYSIS_BW -1:0] Y3_real;
reg signed [`ANALYSIS_BW -1:0] Y3_imag;
reg signed [`ANALYSIS_BW -1:0] Y4_real;
reg signed [`ANALYSIS_BW -1:0] Y4_imag;
reg signed [`ANALYSIS_BW -1:0] Y5_real;
reg signed [`ANALYSIS_BW -1:0] Y5_imag;
reg signed [`ANALYSIS_BW -1:0] Y6_real;
reg signed [`ANALYSIS_BW -1:0] Y6_imag;
reg signed [`ANALYSIS_BW -1:0] Y7_real;
reg signed [`ANALYSIS_BW -1:0] Y7_imag;
reg signed [`ANALYSIS_BW -1:0] Y8_real;
reg signed [`ANALYSIS_BW -1:0] Y8_imag;
reg signed [`ANALYSIS_BW -1:0] Y9_real;
reg signed [`ANALYSIS_BW -1:0] Y9_imag;
reg signed [`ANALYSIS_BW -1:0] Y10_real;
reg signed [`ANALYSIS_BW -1:0] Y10_imag;
reg signed [`ANALYSIS_BW -1:0] Y11_real;
reg signed [`ANALYSIS_BW -1:0] Y11_imag;
reg signed [`ANALYSIS_BW -1:0] Y12_real;
reg signed [`ANALYSIS_BW -1:0] Y12_imag;
reg signed [`ANALYSIS_BW -1:0] Y13_real;
reg signed [`ANALYSIS_BW -1:0] Y13_imag;
reg signed [`ANALYSIS_BW -1:0] Y14_real;
reg signed [`ANALYSIS_BW -1:0] Y14_imag;
reg signed [`ANALYSIS_BW -1:0] Y15_real;
reg signed [`ANALYSIS_BW -1:0] Y15_imag;

wire signed [`ANALYSIS_BW*2 -1:0] Y0_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y1_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y2_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y3_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y4_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y5_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y6_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y7_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y8_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y9_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y10_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y11_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y12_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y13_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y14_len;
wire signed [`ANALYSIS_BW*2 -1:0] Y15_len;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_1;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_2;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_3;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_4;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_5;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_6;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_7;
wire signed [`ANALYSIS_BW*2 -1:0] compare_1_8;
wire signed [`ANALYSIS_BW*2 -1:0] compare_2_1;
wire signed [`ANALYSIS_BW*2 -1:0] compare_2_2;
wire signed [`ANALYSIS_BW*2 -1:0] compare_2_3;
wire signed [`ANALYSIS_BW*2 -1:0] compare_2_4;
wire signed [`ANALYSIS_BW*2 -1:0] compare_3_1;
wire signed [`ANALYSIS_BW*2 -1:0] compare_3_2;
wire signed [`ANALYSIS_BW*2 -1:0] compare_4_1;

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
        Y0_imag <= 0;
        Y1_real <= 0;
        Y1_imag <= 0;
        Y2_real <= 0;
        Y2_imag <= 0;
        Y3_real <= 0;
        Y3_imag <= 0;
        Y4_real <= 0;
        Y4_imag <= 0;
        Y5_real <= 0;
        Y5_imag <= 0;
        Y6_real <= 0;
        Y6_imag <= 0;
        Y7_real <= 0;
        Y7_imag <= 0;
        Y8_real <= 0;
        Y8_imag <= 0;
        Y9_real <= 0;
        Y9_imag <= 0;
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
        Y0_real <= {fft_d0[`BW*2 -1], fft_d0[`BW+`ANALYSIS_BW -2:`BW]};
        Y0_imag <= {fft_d0[`BW -1], fft_d0[`ANALYSIS_BW -2:0]};
        Y1_real <= {fft_d1[`BW*2 -1], fft_d1[`BW+`ANALYSIS_BW -2:`BW]};
        Y1_imag <= {fft_d1[`BW -1], fft_d1[`ANALYSIS_BW -2:0]};
        Y2_real <= {fft_d2[`BW*2 -1], fft_d2[`BW+`ANALYSIS_BW -2:`BW]};
        Y2_imag <= {fft_d2[`BW -1], fft_d2[`ANALYSIS_BW -2:0]};
        Y3_real <= {fft_d3[`BW*2 -1], fft_d3[`BW+`ANALYSIS_BW -2:`BW]};
        Y3_imag <= {fft_d3[`BW -1], fft_d3[`ANALYSIS_BW -2:0]};
        Y4_real <= {fft_d4[`BW*2 -1], fft_d4[`BW+`ANALYSIS_BW -2:`BW]};
        Y4_imag <= {fft_d4[`BW -1], fft_d4[`ANALYSIS_BW -2:0]};
        Y5_real <= {fft_d5[`BW*2 -1], fft_d5[`BW+`ANALYSIS_BW -2:`BW]};
        Y5_imag <= {fft_d5[`BW -1], fft_d5[`ANALYSIS_BW -2:0]};
        Y6_real <= {fft_d6[`BW*2 -1], fft_d6[`BW+`ANALYSIS_BW -2:`BW]};
        Y6_imag <= {fft_d6[`BW -1], fft_d6[`ANALYSIS_BW -2:0]};
        Y7_real <= {fft_d7[`BW*2 -1], fft_d7[`BW+`ANALYSIS_BW -2:`BW]};
        Y7_imag <= {fft_d7[`BW -1], fft_d7[`ANALYSIS_BW -2:0]};
        Y8_real <= {fft_d8[`BW*2 -1], fft_d8[`BW+`ANALYSIS_BW -2:`BW]};
        Y8_imag <= {fft_d8[`BW -1], fft_d8[`ANALYSIS_BW -2:0]};
        Y9_real <= {fft_d9[`BW*2 -1], fft_d9[`BW+`ANALYSIS_BW -2:`BW]};
        Y9_imag <= {fft_d9[`BW -1], fft_d9[`ANALYSIS_BW -2:0]};
        Y10_real <= {fft_d10[`BW*2 -1], fft_d10[`BW+`ANALYSIS_BW -2:`BW]};
        Y10_imag <= {fft_d10[`BW -1], fft_d10[`ANALYSIS_BW -2:0]};
        Y11_real <= {fft_d11[`BW*2 -1], fft_d11[`BW+`ANALYSIS_BW -2:`BW]};
        Y11_imag <= {fft_d11[`BW -1], fft_d11[`ANALYSIS_BW -2:0]};
        Y12_real <= {fft_d12[`BW*2 -1], fft_d12[`BW+`ANALYSIS_BW -2:`BW]};
        Y12_imag <= {fft_d12[`BW -1], fft_d12[`ANALYSIS_BW -2:0]};
        Y13_real <= {fft_d13[`BW*2 -1], fft_d13[`BW+`ANALYSIS_BW -2:`BW]};
        Y13_imag <= {fft_d13[`BW -1], fft_d13[`ANALYSIS_BW -2:0]};
        Y14_real <= {fft_d14[`BW*2 -1], fft_d14[`BW+`ANALYSIS_BW -2:`BW]};
        Y14_imag <= {fft_d14[`BW -1], fft_d14[`ANALYSIS_BW -2:0]};
        Y15_real <= {fft_d15[`BW*2 -1], fft_d15[`BW+`ANALYSIS_BW -2:`BW]};
        Y15_imag <= {fft_d15[`BW -1], fft_d15[`ANALYSIS_BW -2:0]};
        done_buf <= 1'b1;
    end
    else if (done_buf) begin
        done <= 1'b1;
    end
end

endmodule

module FFT_4points_L_0 (a, b, c, d, o1, o2, o3, o4);
input signed [`BW -1:0] a, b, c, d;
output signed [`FFT_OUT_L_UP_BW -1:0] o1;
output signed [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire signed [`BW :0] a_a_c, b_a_d;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] a_m_c, b_m_d, d_m_b;
wire signed [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] o2_real;

assign a_a_c = a + c;
assign b_a_d = b + d;
assign a_m_c = a - c;
assign b_m_d = b - d; // maybe can optimize: d_m_b = -(b_m_d)
assign d_m_b = d - b;

assign o1_real = a_a_c + b_a_d;
assign o2_real = a_a_c - b_a_d;

assign o1 = {o1_real};
assign o2 = {o2_real, `FFT_OUT_L_DOWN_BW'b0};
assign o3 = {a_m_c, d_m_b};
assign o4 = {a_m_c, b_m_d};
    
endmodule

module FFT_4points_L_1 (a, b, c, d, o1, o2, o3, o4);
parameter signed [`FFT_W_BW -1:0] w1_real = 32'h0000EC83;
parameter signed [`FFT_W_BW -1:0] w1_imag = 32'hFFFF9E09;
parameter signed [`FFT_W_BW -1:0] w2_real = 32'h0000B504;
parameter signed [`FFT_W_BW -1:0] w2_imag = 32'hFFFF4AFC;
input signed [`BW -1:0] a, b, c, d;
output signed [`FFT_OUT_L_UP_BW -1:0] o1;
output signed [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire signed [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d, aac_m_bad;
wire signed [`BW + `FFT_W_BW -1:0] amc_w1r, amc_w1i, bmd_w1r, bmd_w1i;
wire signed [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire signed[`FFT_OUT_L_DOWN_BW -1:0] o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = a + c;
assign b_a_d = b + d;
assign a_m_c = a - c;
assign b_m_d = b - d;
assign aac_m_bad = a_a_c - b_a_d;
assign amc_w1r = a_m_c * w1_real;
assign amc_w1i = a_m_c * w1_imag;
assign bmd_w1r = b_m_d * w1_real;
assign bmd_w1i = b_m_d * w1_imag;

assign o1_real = a_a_c + b_a_d;
assign o2_real = aac_m_bad * w2_real;
assign o2_imag = aac_m_bad * w2_imag;
assign o3_real = amc_w1r + bmd_w1i;
assign o3_imag = amc_w1i - bmd_w1r;
assign o4_real = (amc_w1r + bmd_w1r + amc_w1i - bmd_w1i) * w2_real;
assign o4_imag = (bmd_w1r - amc_w1r + amc_w1i + bmd_w1i) * w2_real;

assign o1 = {o1_real};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_L_2 (a, b, c, d, o1, o2, o3, o4);
parameter signed [`FFT_W_BW -1:0] w2_real = 32'h0000B504;
parameter signed [`FFT_W_BW -1:0] w2_imag = 32'hFFFF4AFC;
input signed [`BW -1:0] a, b, c, d;
output signed [`FFT_OUT_L_UP_BW -1:0] o1;
output signed [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire signed [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d;
wire signed [`BW +1:0] amc_m_bmd, amc_a_bmd;
wire signed [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = a + c;
assign b_a_d = b + d;
assign a_m_c = a - c;
assign b_m_d = b - d;

assign amc_m_bmd = a_m_c - b_m_d;
assign amc_a_bmd = a_m_c + b_m_d;

assign o1_real = a_a_c + b_a_d;
assign o2_imag = b_a_d - a_a_c;
assign o3_real = amc_m_bmd * w2_real;
assign o3_imag = amc_a_bmd * w2_imag;
assign o4_real = amc_m_bmd * w2_imag;
assign o4_imag = amc_a_bmd * w2_imag;

assign o1 = {o1_real};
assign o2 = {`FFT_OUT_L_DOWN_BW'b0, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_L_3 (a, b, c, d, o1, o2, o3, o4);
parameter signed [`FFT_W_BW -1:0] w3_real = 32'h000061F7;
parameter signed [`FFT_W_BW -1:0] w3_imag = 32'hFFFF137D;
parameter signed [`FFT_W_BW -1:0] w6_real = 32'hFFFF4AFC;
input signed [`BW -1:0] a, b, c, d;
output signed [`FFT_OUT_L_UP_BW -1:0] o1;
output signed [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire signed [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d, aac_m_bad;
wire signed [`BW + `FFT_W_BW -1:0] amc_w3r, bmd_w3i, amc_w3i, bmd_w3r;
wire signed [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = a + c;
assign b_a_d = b + d;
assign a_m_c = a - c;
assign b_m_d = b - d;

assign aac_m_bad = a_a_c - b_a_d;
assign amc_w3r = a_m_c * w3_real;
assign bmd_w3i = b_m_d * w3_imag;
assign amc_w3i = a_m_c * w3_imag;
assign bmd_w3r = b_m_d * w3_real;

assign o1_real = a_a_c + b_a_d;
assign o2_real = aac_m_bad * w6_real;
assign o2_imag = o2_real;
assign o3_real = amc_w3r + bmd_w3i;
assign o3_imag = amc_w3i - bmd_w3r;
assign o4_real = (amc_w3r - bmd_w3r - bmd_w3i - amc_w3i) * w6_real;
assign o4_imag = (amc_w3r + bmd_w3r - bmd_w3i + amc_w3i) * w6_real;

assign o1 = {o1_real};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};

endmodule

module FFT_4points_R_0 (a, b, c, d, o1, o2, o3, o4);
input signed [`FFT_OUT_L_UP_BW -1:0] a, b, c, d;
output signed [`FFT_OUT_R_UP_BW -1:0] o1;
output signed [`FFT_OUT_R_UP_BW*2 -1:0] o2, o3, o4;

wire signed [`FFT_OUT_L_UP_BW :0] a_a_c, b_a_d;
wire signed [`FFT_OUT_R_UP_BW -1:0] o1_real, o2_real, a_m_c, b_m_d, d_m_b;

assign a_a_c = a + c;
assign b_a_d = b + d;
assign a_m_c = a - c;
assign b_m_d = b - d;
assign d_m_b = d - b;

assign o1_real = a_a_c + b_a_d;
assign o2_real = a_a_c - b_a_d;

assign o1 = {o1_real};
assign o2 = {o2_real, `FFT_OUT_R_UP_BW'b0};
assign o3 = {a_m_c, d_m_b};
assign o4 = {a_m_c, b_m_d};
    
endmodule

module FFT_4points_R_1 (a, b, c, d, o1, o2, o3, o4);
input signed [`FFT_OUT_L_DOWN_BW*2 -1:0] a, b, c, d;
output signed [`FFT_OUT_R_DOWN_BW*2 -1:0] o1, o2, o3, o4;

wire signed [`FFT_OUT_L_DOWN_BW -1:0] a_r, a_i, b_r, b_i, c_r, c_i, d_r, d_i;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] br_a_dr_, bi_a_di_, bi_m_di_, dr_m_br_;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] ar_a_cr, br_a_dr, ai_a_ci, bi_a_di, ar_m_cr, bi_m_di, ai_m_ci, dr_m_br;
wire signed [`FFT_OUT_R_DOWN_BW -1:0] o1_real, o1_imag, o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign a_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign b_r = b[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign b_i = b[`FFT_OUT_L_DOWN_BW -1:0];
assign c_r = c[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign c_i = c[`FFT_OUT_L_DOWN_BW -1:0];
assign d_r = d[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign d_i = d[`FFT_OUT_L_DOWN_BW -1:0];

assign ar_a_cr = a_r + c_r;
assign br_a_dr_ = b_r + d_r;
assign ai_a_ci = a_i + c_i;
assign bi_a_di_ = b_i + d_i;
assign ar_m_cr = a_r - c_r;
assign bi_m_di_ = b_i - d_i;
assign ai_m_ci = a_i - c_i;
assign dr_m_br_ = d_r - b_r;

round_FFT_OUT_L_DOWN_BW_16 round1(.x(br_a_dr_), .rounded_x(br_a_dr));
round_FFT_OUT_L_DOWN_BW_16 round2(.x(bi_a_di_), .rounded_x(bi_a_di));
round_FFT_OUT_L_DOWN_BW_16 round3(.x(bi_m_di_), .rounded_x(bi_m_di));
round_FFT_OUT_L_DOWN_BW_16 round4(.x(dr_m_br_), .rounded_x(dr_m_br));

assign o1_real = ar_a_cr + br_a_dr;
assign o1_imag = ai_a_ci + bi_a_di;
assign o2_real = ar_a_cr - br_a_dr;
assign o2_imag = ai_a_ci - bi_a_di;
assign o3_real = ar_m_cr + bi_m_di;
assign o3_imag = ai_m_ci + dr_m_br;
assign o4_real = ar_m_cr - bi_m_di;
assign o4_imag = ai_m_ci - dr_m_br;

assign o1 = {o1_real, o1_imag};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_R_2 (a, b, c, d, o1, o2, o3, o4);
input signed [`FFT_OUT_L_DOWN_BW*2 -1:0] a, b, c, d;
output signed [`FFT_OUT_R_DOWN_BW*2 -1:0] o1, o2, o3, o4;

wire signed [`FFT_OUT_L_DOWN_BW -1:0] c_r_, c_i_;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] a_r, a_i, b_r, b_i, c_r, c_i, d_r, d_i;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] br_a_dr_, bi_a_di_, bi_m_di_, dr_m_br_;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] ar_a_cr, br_a_dr, ai_a_ci, bi_a_di, ar_m_cr, bi_m_di, ai_m_ci, dr_m_br;
wire signed [`FFT_OUT_R_DOWN_BW -1:0] o1_real, o1_imag, o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign a_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign b_r = b[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign b_i = b[`FFT_OUT_L_DOWN_BW -1:0];
assign c_r_ = c[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign c_i_ = c[`FFT_OUT_L_DOWN_BW -1:0];
assign d_r = d[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign d_i = d[`FFT_OUT_L_DOWN_BW -1:0];

round_FFT_OUT_L_DOWN_BW_16 round1(.x(c_r_), .rounded_x(c_r));
round_FFT_OUT_L_DOWN_BW_16 round2(.x(c_i_), .rounded_x(c_i));

assign ar_a_cr = a_r + c_r;
assign br_a_dr_ = b_r + d_r;
assign ai_a_ci = a_i + c_i;
assign bi_a_di_ = b_i + d_i;
assign ar_m_cr = a_r - c_r;
assign bi_m_di_ = b_i - d_i;
assign ai_m_ci = a_i - c_i;
assign dr_m_br_ = d_r - b_r;

round_FFT_OUT_L_DOWN_BW_16 round3(.x(br_a_dr_), .rounded_x(br_a_dr));
round_FFT_OUT_L_DOWN_BW_16 round4(.x(bi_a_di_), .rounded_x(bi_a_di));
round_FFT_OUT_L_DOWN_BW_16 round5(.x(bi_m_di_), .rounded_x(bi_m_di));
round_FFT_OUT_L_DOWN_BW_16 round6(.x(dr_m_br_), .rounded_x(dr_m_br));

assign o1_real = ar_a_cr + br_a_dr;
assign o1_imag = ai_a_ci + bi_a_di;
assign o2_real = ar_a_cr - br_a_dr;
assign o2_imag = ai_a_ci - bi_a_di;
assign o3_real = ar_m_cr + bi_m_di;
assign o3_imag = ai_m_ci + dr_m_br;
assign o4_real = ar_m_cr - bi_m_di;
assign o4_imag = ai_m_ci - dr_m_br;

assign o1 = {o1_real, o1_imag};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_R_3 (a, b, c, d, o1, o2, o3, o4);
input signed [`FFT_OUT_L_DOWN_BW*2 -1:0] a, b, c, d;
output signed [`FFT_OUT_R_DOWN_BW*2 -1:0] o1, o2, o3, o4;

wire signed [`FFT_OUT_L_DOWN_BW -1:0] c_r_, c_i_;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] a_r, a_i, b_r, b_i, c_r, c_i, d_r, d_i;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] br_a_dr_, bi_a_di_, bi_m_di_, dr_m_br_;
wire signed [`FFT_OUT_L_DOWN_BW -1:0] ar_a_cr, br_a_dr, ai_a_ci, bi_a_di, ar_m_cr, bi_m_di, ai_m_ci, dr_m_br;
wire signed [`FFT_OUT_R_DOWN_BW -1:0] o1_real, o1_imag, o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign a_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign b_r = b[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign b_i = b[`FFT_OUT_L_DOWN_BW -1:0];
assign c_r_ = c[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign c_i_ = c[`FFT_OUT_L_DOWN_BW -1:0];
assign d_r = d[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign d_i = d[`FFT_OUT_L_DOWN_BW -1:0];

round_FFT_OUT_L_DOWN_BW_16 round1(.x(c_r_), .rounded_x(c_r));
round_FFT_OUT_L_DOWN_BW_16 round2(.x(c_i_), .rounded_x(c_i));

assign ar_a_cr = a_r + c_r;
assign br_a_dr_ = b_r + d_r;
assign ai_a_ci = a_i + c_i;
assign bi_a_di_ = b_i + d_i;
assign ar_m_cr = a_r - c_r;
assign bi_m_di_ = b_i - d_i;
assign ai_m_ci = a_i - c_i;
assign dr_m_br_ = d_r - b_r;

round_FFT_OUT_L_DOWN_BW_32 round3(.x(br_a_dr_), .rounded_x(br_a_dr));
round_FFT_OUT_L_DOWN_BW_32 round4(.x(bi_a_di_), .rounded_x(bi_a_di));
round_FFT_OUT_L_DOWN_BW_32 round5(.x(bi_m_di_), .rounded_x(bi_m_di));
round_FFT_OUT_L_DOWN_BW_32 round6(.x(dr_m_br_), .rounded_x(dr_m_br));

assign o1_real = ar_a_cr + br_a_dr;
assign o1_imag = ai_a_ci + bi_a_di;
assign o2_real = ar_a_cr - br_a_dr;
assign o2_imag = ai_a_ci - bi_a_di;
assign o3_real = ar_m_cr + bi_m_di;
assign o3_imag = ai_m_ci + dr_m_br;
assign o4_real = ar_m_cr - bi_m_di;
assign o4_imag = ai_m_ci - dr_m_br;

assign o1 = {o1_real, o1_imag};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module from_FFT_OUT_R_DOWN_BW_to_BW (x, rounded_x);
    input [`FFT_OUT_R_DOWN_BW -1:0] x;
    output [`BW -1:0] rounded_x;

    assign rounded_x = {x[`FFT_OUT_R_DOWN_BW -1], x[`BW -2:0]};

endmodule

module round_FFT_OUT_L_DOWN_BW_32(x, rounded_x);
    input signed [`FFT_OUT_L_DOWN_BW -1:0] x;
    output [`FFT_OUT_L_DOWN_BW -1:0] rounded_x;

    // wire carry_bit;
    // wire [`FFT_OUT_L_DOWN_BW -1:0] x_shift;

    // assign carry_bit = (x[`FFT_OUT_L_DOWN_BW-1]) ? (&x[`FFT_OUT_L_DOWN_BW -1:32]) ? 1'b1 : (x[31] && (|x[30:0])) : x[31]; // neg plus one
    // assign carry_bit = (x[`FFT_OUT_L_DOWN_BW-1]) ? (x[31] && (|x[30:0])) : x[31]; // 4out5in
    // assign x_shift = x>>>32;
    // assign rounded_x = x_shift + carry_bit;
    assign rounded_x = x>>>`ZOOM*2; //shift32
endmodule

module round_FFT_OUT_L_DOWN_BW_16(x, rounded_x);
    input signed [`FFT_OUT_L_DOWN_BW -1:0] x;
    output [`FFT_OUT_L_DOWN_BW -1:0] rounded_x;

    // wire carry_bit;
    // wire [`FFT_OUT_L_DOWN_BW -1:0] x_shift;

    // assign carry_bit = (x[`FFT_OUT_L_DOWN_BW-1]) ? (&x[`FFT_OUT_L_DOWN_BW -1:16]) ? 1'b1 : (x[15] && (|x[14:0])) : x[15]; // neg plus one
    // assign carry_bit = (x[`FFT_OUT_L_DOWN_BW-1]) ? (x[15] && (|x[14:0])) : x[15]; // 4out5in
    // assign x_shift = x>>>16;
    // assign rounded_x = x_shift + carry_bit;
    assign rounded_x = x>>>`ZOOM; //shift
endmodule

module round_FFT_OUT_R_DOWN_BW_16 (x, rounded_x);
    input signed [`FFT_OUT_R_DOWN_BW -1:0] x;
    output [`FFT_OUT_R_DOWN_BW -1:0] rounded_x;

    // wire carry_bit;
    // wire [`FFT_OUT_R_DOWN_BW -1:0] x_shift;

    // assign carry_bit = (x[`FFT_OUT_R_DOWN_BW-1]) ? (&x[`FFT_OUT_R_DOWN_BW -1:16]) ? 1'b1 : (x[15] && (|x[14:0])) : x[15]; //neg plus one
    // assign carry_bit = (x[`FFT_OUT_R_DOWN_BW-1]) ? (x[15] && (|x[14:0])) : x[15]; // 4out5in
    // assign x_shift = x>>>16; 
    // assign rounded_x = x_shift + carry_bit;
    assign rounded_x = x>>>`ZOOM; //shift
endmodule

module round_FIR_CAL_OUT_BW_16 (x, rounded_x);
    input signed [`FIR_CAL_OUT_BW -1:0] x;
    output [`BW -1:0] rounded_x;

    wire carry_bit;
    wire [`BW -1:0] x_shift;

    assign x_shift = x>>>`ZOOM;
    // assign carry_bit = (x[36-1]) ? (&x[36 -1:16]) ? 1'b1 : (x[15] && (|x[14:0])) : x[15]; // ffff special case
    // assign carry_bit = x[15]; // 5out6in
    assign carry_bit = x[`FIR_CAL_OUT_BW -1]; // neg plus one
    // assign carry_bit = (x[36-1]) ? (x[15] && (|x[14:0])) : x[15]; // 4out5in
    assign rounded_x = x_shift + carry_bit;
endmodule

