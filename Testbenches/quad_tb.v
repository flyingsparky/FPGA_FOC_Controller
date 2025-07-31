`timescale 1ns / 1ps

module quad_tb ();

reg clk = 0;
reg rst_n = 0;
reg a = 0, b = 0;
wire [15:0] position;
wire [1:0] state;

quad dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .A      (a),
    .B      (b),
    .count  (position),
    // Debug
    .state	(state)
);

always #5 clk = ~clk;

task rotate(input integer dir);
    begin
        if (dir) begin // CW: 00 01 11 10
            {a, b} = 2'b00; #20;
            {a, b} = 2'b01; #20;
            {a, b} = 2'b11; #20;
            {a, b} = 2'b10; #20;
        end else begin // CCW: 00 10 11 01
            {a, b} = 2'b00; #20;
            {a, b} = 2'b10; #20;
            {a, b} = 2'b11; #20;
            {a, b} = 2'b01; #20;
        end
    end
endtask

initial begin
    #10 rst_n = 1;

    repeat (200) rotate(1);
    #1000;

    repeat (200) rotate(0);
    #100 $finish;
end

endmodule