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
wire signed [`FFT_OUT_L_UP_BW -1:0] mid_1, mid_2, mid_3, mid_4;
wire [`FFT_OUT_L_DOWN_BW*2 -1:0] mid_5, mid_6, mid_7, mid_8, mid_9, mid_10, mid_11, mid_12, mid_13, mid_14, mid_15, mid_16;
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
FFT_4points_L_0 fft4pL0(.a(fft_X0_reg), .b(fft_X1_reg), .c(fft_X2_reg), .d(fft_X3_reg), .o1(mid_1), .o2(mid_5), .o3(mid_9), .o4(mid_13));
FFT_4points_L_1 fft4pL1(.a(fft_X4_reg), .b(fft_X5_reg), .c(fft_X6_reg), .d(fft_X7_reg), .o1(mid_2), .o2(mid_6), .o3(mid_10), .o4(mid_14));
FFT_4points_L_2 fft4pL2(.a(fft_X8_reg), .b(fft_X9_reg), .c(fft_X10_reg), .d(fft_X11_reg), .o1(mid_3), .o2(mid_7), .o3(mid_11), .o4(mid_15));
FFT_4points_L_3 fft4pL3(.a(fft_X12_reg), .b(fft_X13_reg), .c(fft_X14_reg), .d(fft_X15_reg), .o1(mid_4), .o2(mid_8), .o3(mid_12), .o4(mid_16));
FFT_4points_R_UP fft4pR0(.a(mid_1), .b(mid_2), .c(mid_3), .d(mid_4), .o1(fft_d0_out), .o2(fft_d8_out), .o3(fft_d4_out), .o4(fft_d12_out));
FFT_4points_R_DOWN fft4pR1(.a(mid_5), .b(mid_6), .c(mid_7), .d(mid_8), .o1(fft_d2_out), .o2(fft_d10_out), .o3(fft_d6_out), .o4(fft_d14_out));
FFT_4points_R_DOWN fft4pR2(.a(mid_9), .b(mid_10), .c(mid_11), .d(mid_12), .o1(fft_d1_out), .o2(fft_d9_out), .o3(fft_d5_out), .o4(fft_d13_out));
FFT_4points_R_DOWN fft4pR3(.a(mid_13), .b(mid_14), .c(mid_15), .d(mid_16), .o1(fft_d3_out), .o2(fft_d11_out), .o3(fft_d7_out), .o4(fft_d15_out));

// round real
round_82to16 ROUND_r_1(.x(fft_d1_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d1_r));
round_82to16 ROUND_r_2(.x(fft_d2_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d2_r));
round_82to16 ROUND_r_3(.x(fft_d3_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d3_r));
round_82to16 ROUND_r_5(.x(fft_d5_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d5_r));
round_82to16 ROUND_r_6(.x(fft_d6_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d6_r));
round_82to16 ROUND_r_7(.x(fft_d7_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d7_r));
round_82to16 ROUND_r_9(.x(fft_d9_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d9_r));
round_82to16 ROUND_r_10(.x(fft_d10_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d10_r));
round_82to16 ROUND_r_11(.x(fft_d11_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d11_r));
round_82to16 ROUND_r_13(.x(fft_d13_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d13_r));
round_82to16 ROUND_r_14(.x(fft_d14_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d14_r));
round_82to16 ROUND_r_15(.x(fft_d15_out[`FFT_OUT_R_DOWN_BW*2 -1:`FFT_OUT_R_DOWN_BW]), .rounded_x(fft_d15_r));

// round imag
round_82to16 ROUND_i_1(.x(fft_d1_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d1_i));
round_82to16 ROUND_i_2(.x(fft_d2_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d2_i));
round_82to16 ROUND_i_3(.x(fft_d3_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d3_i));
round_82to16 ROUND_i_5(.x(fft_d5_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d5_i));
round_82to16 ROUND_i_6(.x(fft_d6_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d6_i));
round_82to16 ROUND_i_7(.x(fft_d7_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d7_i));
round_82to16 ROUND_i_9(.x(fft_d9_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d9_i));
round_82to16 ROUND_i_10(.x(fft_d10_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d10_i));
round_82to16 ROUND_i_11(.x(fft_d11_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d11_i));
round_82to16 ROUND_i_13(.x(fft_d13_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d13_i));
round_82to16 ROUND_i_14(.x(fft_d14_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d14_i));
round_82to16 ROUND_i_15(.x(fft_d15_out[`FFT_OUT_R_DOWN_BW -1:0]), .rounded_x(fft_d15_i));

assign fft_d0 = {fft_d0_out[`FFT_OUT_R_UP_BW-1], fft_d0_out[`BW -2:0], 16'b0};
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

module FFT_4points_L_0 (a, b, c, d, o1, o2, o3, o4);
input [`BW -1:0] a, b, c, d;
output [`FFT_OUT_L_UP_BW -1:0] o1;
output [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire [`BW :0] a_a_c, b_a_d;
wire [`FFT_OUT_L_DOWN_BW -1:0] a_m_c, b_m_d, d_m_b;
wire [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire [`FFT_OUT_L_DOWN_BW -1:0] o2_real;

assign a_a_c = $signed(a) + $signed(c);
assign b_a_d = $signed(b) + $signed(d);
assign a_m_c = $signed(a) - $signed(c);
assign b_m_d = $signed(b) - $signed(d);
assign d_m_b = $signed(d) - $signed(b);

assign o1_real = $signed(a_a_c) + $signed(b_a_d);
assign o2_real = $signed(a_a_c) - $signed(b_a_d);

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
input [`BW -1:0] a, b, c, d;
output [`FFT_OUT_L_UP_BW -1:0] o1;
output [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d, aac_m_bad;
wire [`BW + `FFT_W_BW -1:0] amc_w1r, amc_w1i, bmd_w1r, bmd_w1i;
wire [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire [`FFT_OUT_L_DOWN_BW -1:0] o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = $signed(a) + $signed(c);
assign b_a_d = $signed(b) + $signed(d);
assign a_m_c = $signed(a) - $signed(c);
assign b_m_d = $signed(b) - $signed(d);
assign aac_m_bad = $signed(a_a_c) - $signed(b_a_d);
assign amc_w1r = $signed(a_m_c) * $signed(w1_real);
assign amc_w1i = $signed(a_m_c) * $signed(w1_imag);
assign bmd_w1r = $signed(b_m_d) * $signed(w1_real);
assign bmd_w1i = $signed(b_m_d) * $signed(w1_imag);

assign o1_real = $signed(a_a_c) + $signed(b_a_d);
assign o2_real = $signed(aac_m_bad) * $signed(w2_real);
assign o2_imag = $signed(aac_m_bad) * $signed(w2_imag);
assign o3_real = $signed(amc_w1r) + $signed(bmd_w1i);
assign o3_imag = $signed(amc_w1i) - $signed(bmd_w1r);
assign o4_real = ($signed(amc_w1r) + $signed(bmd_w1r) + $signed(amc_w1i) - $signed(bmd_w1i)) * $signed(w2_real);
assign o4_imag = ($signed(bmd_w1r) - $signed(amc_w1r) + $signed(amc_w1i) + $signed(bmd_w1i)) * $signed(w2_real);

assign o1 = {o1_real};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_L_2 (a, b, c, d, o1, o2, o3, o4);
parameter signed [`FFT_W_BW -1:0] w2_real = 32'h0000B504;
parameter signed [`FFT_W_BW -1:0] w2_imag = 32'hFFFF4AFC;
input [`BW -1:0] a, b, c, d;
output [`FFT_OUT_L_UP_BW -1:0] o1;
output [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d;
wire [`BW +1:0] amc_m_bmd, amc_a_bmd;
wire [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire [`FFT_OUT_L_DOWN_BW -1:0] o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = $signed(a) + $signed(c);
assign b_a_d = $signed(b) + $signed(d);
assign a_m_c = $signed(a) - $signed(c);
assign b_m_d = $signed(b) - $signed(d);

assign amc_m_bmd = $signed(a_m_c) - $signed(b_m_d);
assign amc_a_bmd = $signed(a_m_c) + $signed(b_m_d);

assign o1_real = $signed(a_a_c) + $signed(b_a_d);
assign o2_imag = $signed(b_a_d) - $signed(a_a_c);
assign o3_real = $signed(amc_m_bmd) * $signed(w2_real);
assign o3_imag = $signed(amc_a_bmd) * $signed(w2_imag);
assign o4_real = $signed(amc_m_bmd) * $signed(w2_imag);
assign o4_imag = $signed(amc_a_bmd) * $signed(w2_imag);

assign o1 = {o1_real};
assign o2 = {`FFT_OUT_L_DOWN_BW'b0, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module FFT_4points_L_3 (a, b, c, d, o1, o2, o3, o4);
parameter signed [`FFT_W_BW -1:0] w3_real = 32'h000061F7;
parameter signed [`FFT_W_BW -1:0] w3_imag = 32'hFFFF137D;
parameter signed [`FFT_W_BW -1:0] w6_real = 32'hFFFF4AFC;
parameter signed [`FFT_W_BW -1:0] w6_imag = 32'hFFFF4AFC;
input [`BW -1:0] a, b, c, d;
output [`FFT_OUT_L_UP_BW -1:0] o1;
output [`FFT_OUT_L_DOWN_BW*2 -1:0] o2, o3, o4;

wire [`BW :0] a_a_c, b_a_d, a_m_c, b_m_d, aac_m_bad;
wire [`BW + `FFT_W_BW -1:0] amc_w3r, bmd_w3i, amc_w3i, bmd_w3r;
wire [`FFT_OUT_L_UP_BW -1:0] o1_real;
wire [`FFT_OUT_L_DOWN_BW -1:0] o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_a_c = $signed(a) + $signed(c);
assign b_a_d = $signed(b) + $signed(d);
assign a_m_c = $signed(a) - $signed(c);
assign b_m_d = $signed(b) - $signed(d);

assign aac_m_bad = $signed(a_a_c) - $signed(b_a_d);
assign amc_w3r = $signed(a_m_c) * $signed(w3_real);
assign bmd_w3i = $signed(b_m_d) * $signed(w3_imag);
assign amc_w3i = $signed(a_m_c) * $signed(w3_imag);
assign bmd_w3r = $signed(b_m_d) * $signed(w3_real);

assign o1_real = $signed(a_a_c) + $signed(b_a_d);
assign o2_real = $signed(aac_m_bad) * $signed(w6_real);
assign o2_imag = $signed(aac_m_bad) * $signed(w6_imag);
assign o3_real = $signed(amc_w3r) + $signed(bmd_w3i);
assign o3_imag = $signed(amc_w3i) - $signed(bmd_w3r);
assign o4_real = ($signed(amc_w3r) - $signed(bmd_w3r) - $signed(bmd_w3i) - $signed(amc_w3i)) * $signed(w6_real);
assign o4_imag = ($signed(amc_w3r) + $signed(bmd_w3r) + $signed(bmd_w3i) - $signed(amc_w3i)) * $signed(w6_real);

assign o1 = {o1_real};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};

endmodule

module FFT_4points_R_UP (a, b, c, d, o1, o2, o3, o4);
input [`FFT_OUT_L_UP_BW -1:0] a, b, c, d;
output [`FFT_OUT_R_UP_BW -1:0] o1;
output [`FFT_OUT_R_UP_BW*2 -1:0] o2, o3, o4;

wire [`FFT_OUT_L_UP_BW :0] a_a_c, b_a_d, a_m_c, b_m_d, d_m_b;
wire [`FFT_OUT_R_UP_BW -1:0] o1_real, o2_real;

assign a_a_c = $signed(a) + $signed(c);
assign b_a_d = $signed(b) + $signed(d);
assign a_m_c = $signed(a) - $signed(c);
assign b_m_d = $signed(b) - $signed(d);
assign d_m_b = $signed(d) - $signed(b);

assign o1_real = $signed(a_a_c) + $signed(b_a_d);
assign o2_real = $signed(a_a_c) - $signed(b_a_d);

assign o1 = {o1_real};
assign o2 = {o2_real, `FFT_OUT_R_UP_BW'b0};
assign o3 = {a_m_c, d_m_b};
assign o4 = {a_m_c, b_m_d};
    
endmodule

module FFT_4points_R_DOWN (a, b, c, d, o1, o2, o3, o4);
input [`FFT_OUT_L_DOWN_BW*2 -1:0] a, b, c, d;
output [`FFT_OUT_R_DOWN_BW*2 -1:0] o1, o2, o3, o4;

wire [`FFT_OUT_L_DOWN_BW -1:0] a_r, a_i, b_r, b_i, c_r, c_i, d_r, d_i;
wire [`FFT_OUT_L_DOWN_BW :0] ar_a_cr, br_a_dr, ai_a_ci, bi_a_di, ar_m_cr, bi_m_di, ai_m_ci, dr_m_br;
wire [`FFT_OUT_R_DOWN_BW -1:0] o1_real, o1_imag, o2_real, o2_imag, o3_real, o3_imag, o4_real, o4_imag;

assign a_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign a_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign b_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign b_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign c_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign c_i = a[`FFT_OUT_L_DOWN_BW -1:0];
assign d_r = a[`FFT_OUT_L_DOWN_BW*2 -1:`FFT_OUT_L_DOWN_BW];
assign d_i = a[`FFT_OUT_L_DOWN_BW -1:0];

assign ar_a_cr = $signed(a_r) + $signed(c_r);
assign br_a_dr = $signed(b_r) + $signed(d_r);
assign ai_a_ci = $signed(a_i) + $signed(c_i);
assign bi_a_di = $signed(b_i) + $signed(d_i);
assign ar_m_cr = $signed(a_r) - $signed(c_r);
assign bi_m_di = $signed(b_i) - $signed(d_i);
assign ai_m_ci = $signed(a_i) - $signed(c_i);
assign dr_m_br = $signed(d_r) - $signed(b_r);

assign o1_real = $signed(ar_a_cr) + $signed(br_a_dr);
assign o1_imag = $signed(ai_a_ci) + $signed(bi_a_di);
assign o2_real = $signed(ar_a_cr) - $signed(br_a_dr);
assign o2_imag = $signed(ai_a_ci) - $signed(bi_a_di);
assign o3_real = $signed(ar_m_cr) + $signed(bi_m_di);
assign o3_imag = $signed(ai_m_ci) + $signed(dr_m_br);
assign o4_real = $signed(ar_m_cr) - $signed(bi_m_di);
assign o4_imag = $signed(ai_m_ci) - $signed(dr_m_br);

assign o1 = {o1_real, o1_imag};
assign o2 = {o2_real, o2_imag};
assign o3 = {o3_real, o3_imag};
assign o4 = {o4_real, o4_imag};
    
endmodule

module round_82to16 (x, rounded_x);
    input [`FFT_OUT_R_DOWN_BW -1:0] x;
    output [`BW -1:0] rounded_x;

    wire carry_bit;

    assign carry_bit = (x[81]) ? (x[15] && (|x[14:0])) : x[15];
    assign rounded_x = {x[81], (x[30:16] + carry_bit)};

endmodule
