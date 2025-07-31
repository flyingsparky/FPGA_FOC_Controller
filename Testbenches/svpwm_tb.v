`timescale 1ps / 1ps

module swpwm_tb();

reg rst_n = 1'b0;
reg clk   = 1'b1;
always #(4883) clk = ~clk;   // 102.4 MHz

reg         [15:0] theta = 0;
wire signed [15:0] x, y;
wire        [15:0] mag;
wire        [15:0] phase;

wire pwm_a, pwm_b, pwm_c;
wire pwm_an, pwm_bn, pwm_cn;

sin_lut sin(
    .rst_n      (rst_n),
    .clk        (clk),
    .i_ph       (theta),
    .o_sin      (y)
);

wire [15:0] cos_ph = theta + 16'h3fff;
sin_lut cos(
    .rst_n      (rst_n),
    .clk        (clk),
    .i_ph       (cos_ph),
    .o_sin      (x)
);

topolar topolar_inst(
    .i_reset    (~rst_n),
    .i_clk      (clk),
    .i_ce       (rst_n),
    .i_xval     (x),
    .i_yval     (y),
    .o_mag      (mag),
    .o_phase    (phase),
    .i_aux      (),
    .o_aux      ()
);

wire [10:0] counter;
wire [15:0] T0d2, T1, T2;
wire [9:0]  Ta, Tb, Tc;
wire [2:0]  sector;

my_svpwm my_svpwm_inst(
    .rst_n      (rst_n),
    .clk        (clk),
    .v_amp      (9'd400),
    .v_ph_i     (phase),
    .v_mag_i    (mag),
    .pwm_a      (pwm_a),
    .pwm_b      (pwm_b),
    .pwm_c      (pwm_c),
    .pwm_an     (pwm_an),
    .pwm_bn     (pwm_bn),
    .pwm_cn     (pwm_cn)
    // Debug
    // .counter(counter),
    // .sector(sector),
    // .T1(T1),
    // .T2(T2),
    // .T0d2(T0d2),
    // .Ta(Ta),
    // .Tb(Tb),
    // .Tc(Tc)
);

initial begin
    #100 rst_n = 1;
    forever begin
        #1000000 theta = theta + 10;
    end
    $finish;
end

endmodule
