`timescale 1ns / 1ps

module clarkepark_tb ();

reg rst_n = 1'b0;
reg clk = 1'b1;
always #10 clk = ~clk;

localparam [15:0] PI    = 16'h7fff;
localparam [15:0] PI2D3 = 16'd21845;
localparam [15:0] PI4D3 = 16'd43690;

reg [15:0] theta = 0;

wire signed [15:0] alpha, beta;
wire signed [15:0] ia, ib, ic;
wire signed [16:0] a1, b1;
wire signed [15:0] id, iq;

sin_lut sin_a (
    .rst_n  (rst_n),
    .clk    (clk),
    .i_ph   (theta + PI),
    .o_sin  (ia)
);

sin_lut sin_b (
    .rst_n  (rst_n),
    .clk    (clk),
    .i_ph   (theta - PI2D3 + PI),
    .o_sin  (ib)
);

sin_lut sin_c (
    .rst_n  (rst_n),
    .clk    (clk),
    .i_ph   (theta - PI4D3 + PI),
    .o_sin  (ic)
);

clarke clarke_inst (
    .rst_n  (rst_n),
    .clk    (clk),
    .ia     (ia),
    .ib     (ib),
    .alpha  (alpha),
    .beta   (beta)
    // .a1(a1),
    // .b1(b1)
);

wire [2:0] counter;
wire signed [16:0] temp1, temp2;
wire signed [31:0] sim_mult_o1, sim_mult_o2;

park park_inst (
    .rst_n  (rst_n),
    .clk    (clk),
    .phi    (theta),
    .alpha  (alpha),
    .beta   (beta),
    .id     (id),
    .iq     (iq)
    // .counter(counter),
    // .temp1(temp1),
    // .temp2(temp2)
);

initial begin
    #100 rst_n = 1;

    forever begin
        #100 theta = theta + 10;
    end
    $finish;
end

endmodule
