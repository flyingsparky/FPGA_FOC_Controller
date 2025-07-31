module clarke (
    input wire                  clk,
    input wire                  rst_n,
    input wire signed [15:0]    ia, ib,
    output reg signed [15:0]    alpha, beta

    // Debug
    // output reg signed [16:0] a1, b1
);

reg  signed [15:0]  mult1;
reg  signed [15:0]  mult2;
wire signed [31:0]  mult_o = mult1 * mult2;    // Reusable DSP mult
reg  signed [16:0]  a1, b1;
reg  signed [16:0]  beta_temp;

localparam INVROOT3 = 32'd18919;  // 1/sqrt(3) * 2^15 = 18918

reg [1:0] count;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count      <= 0;
        alpha      <= 0;
        beta       <= 0;
        mult1      <= 0;
        mult2      <= 0;
        a1         <= 0;
        b1         <= 0;
        beta_temp  <= 0;
    end else begin
        count <= count + 1'd1;
        case (count)
            2'd0: begin
                mult1 <= INVROOT3;
                mult2 <= ia;
            end
            2'd1: begin
                a1    <= mult_o >>> 15;
                mult2 <= ib;
            end
            2'd2: begin
                b1    <= mult_o >>> 14;    // 2/sqrt(3) * ib
            end
            2'd3: begin
                alpha     <= ia;
                beta_temp <= a1 + b1;
                count     <= 2'd0;
            end
        endcase

        if (beta_temp > 17'sh7fff)
            beta <= 16'h7fff;
        else if (beta_temp < -17'sh7fff)
            beta <= -16'sh7fff;
        else
            beta <= beta_temp;
    end
end

endmodule
