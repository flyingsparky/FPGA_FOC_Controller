`timescale 1ns / 1ps

module pi_ctrl_tb( );
reg  clk = 0;
reg  rst_n = 0;
reg  signed [15:0] setpoint = 0;
reg  signed [15:0] feedback = 0;
reg  [31:0] Kp = 0;
reg  [31:0] Ki = 0;
wire signed [15:0] out;


wire [3:0] stage;
wire [31:0] e;
wire [31:0] e_i;
wire [31:0] e_p;
wire [41:0] e_int;
wire [41:0] e_int_prev;
wire [1:0] sat_dir;
wire accum_e_int;

pi_ctrl DUT(
    .rst_n(rst_n),
    .clk(clk),
    .en_i(rst_n),
    .ref_i(setpoint),
    .feed_i(feedback),
    .Kp(Kp),
    .Ki(Ki),
    .out(out),
    // Sim
    .stage(stage),
    .e(e),
    .e_i(e_i),
    .e_p(e_p),
    .e_int(e_int),
    .e_int_prev(e_int_prev),
    .sat_dir(sat_dir),
    .accum_e_int(accum_e_int)
);

initial begin
    rst_n <= 0; // Assert reset
    setpoint <= 10000;
    Kp <= 50000;
    Ki <= 1000000;
    #10000 rst_n <= 1; // Deassert reset
end

always #1 clk = ~clk;
always #10 feedback <= feedback + out/3000;
//    always begin
//        #1000000 feedback <= 1;
//        #1000000 feedback <= 5;
//        #1000000 feedback <= 8;
//        #1000000 feedback <= 10; 
//        #1000000 feedback <= 13;     
//        #1000000 feedback <= 15;     
//        #1000000 feedback <= 16;  
//        #1000000 feedback <= 25;   
//        #1000000 feedback <= 27;
//        #1000000 feedback <= 23;
//        #1000000 feedback <= 19;
//        #1000000 feedback <= 20;
//        #1000000 feedback <= 20;
//        #1000000 feedback <= 20;

//        #100 $finish;
//    end

endmodule