`timescale 1ns / 1ps

module adc_start_tb();

reg clk = 0;
reg rst_n = 0;

always #1 clk = ~clk;

reg in = 0;
wire start_conv;
wire [7:0] counter;

always #200 in = ~in;

adc_start adc_start_inst (
    .rst_n      (rst_n),
    .clk        (clk),
    .in         (in),
    .start_conv (start_conv),
    .counter    (counter)
);
initial begin
    #10 rst_n = 1;
end


endmodule