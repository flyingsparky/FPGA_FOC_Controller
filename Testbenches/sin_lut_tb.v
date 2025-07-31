`timescale 1ns / 1ps

module sin_lut_tb();

reg                 clk = 0;
reg                 rst_n = 0;
reg         [15:0]  phase = 0;
wire signed [15:0]  out;

sin_lut DUT (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_ph   (phase),
    .o_sin  (out)
);


initial begin
    rst_n <= 0;
    phase <= 0;
    #10 rst_n <= 1;
end

always #1 clk = ~clk;

always begin
    #10 phase <= phase + 1;
end

endmodule