`timescale 1ns / 1ps

module Earthquake ;
    reg signed [15:0] pattern [0:999];
    integer i;
    integer write_file;

    reg clk, rst;
    reg data_valid;
    reg [15:0] data; 

    wire fir_valid, fft_valid;
    wire [15:0] fir_d;
    wire [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
    wire [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
    wire done;
    wire [3:0] freq;

    FAS fas (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,fft_d1, 
                fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8, fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);
    
    always begin #5 clk=~clk; end

    initial begin
        rst=1; clk=0; data_valid=0;
        write_file=$fopen("EQ_answer.dat","w");
        $readmemh("EQ_pattern1.dat",pattern);
        #10 rst=0;
        #10 data_valid=1;
        for (i=0;i<1000;i=i+1) begin
            if (done) begin
                $fwrite(write_file,"%b\n",freq);
            end
            data=pattern[i];
            #10
        end
        $fclose(write_file);
    end

    initial begin #20000 $finish; end

endmodule
