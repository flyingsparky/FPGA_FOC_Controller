`timescale 1ns / 1ps

module topolar_tb();

reg                 clk = 0;
reg                 rst_n = 0;
reg  signed [15:0]  i_x = 0;
reg  signed [15:0]  i_y = 0;
wire signed [15:0]  o_mag, o_ph;

reg i_aux;
wire o_aux;

topolar DUT(
    .i_clk      (clk),
    .i_reset    (~rst_n),
    .i_ce       (rst_n),
    .i_xval     (i_x),
    .i_yval     (i_y),
    .o_mag      (o_mag),
    .o_phase    (o_ph),
    .i_aux      (i_aux),
    .o_aux      (o_aux)
);

initial begin
    rst_n = 0;
    i_x = 0;
    i_y = 0;
    i_aux = 0;
    #10 rst_n = 1;
end

always #1 clk = ~clk;

always begin
    #10 begin i_x =  16'd0;      i_y =  16'd0;      i_aux = 0; end
    #10 begin i_x =  16'd100;    i_y =  16'd100;    i_aux = 1; end
    #10 begin i_x =  16'd1000;   i_y =  16'd1000;   i_aux = 0; end
    #10 begin i_x =  16'h7000;   i_y =  16'h7000;   i_aux = 1; end
    #10 begin i_x =  16'h7fff;   i_y =  16'h0000;   i_aux = 0; end
    #10 begin i_x =  16'h0000;   i_y = -16'sh7fff;  i_aux = 0; end
    #10 begin i_x = -16'sh7fff;  i_y =  16'h0000;   i_aux = 0; end

    #200 $finish;
end

endmodule
