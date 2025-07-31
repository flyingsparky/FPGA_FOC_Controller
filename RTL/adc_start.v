module adc_start # (
    parameter [7:0] T_ACQUISITION = 8'd120  // Track-hold acquisition time is 1us, set to approx 1.2us at 102.4Mhz
) (
    input wire	rst_n,
    input wire	clk,
    input wire	in,             // AND three lower outputs
    output reg	start_conv      // 1 cycle high, T_ACQUISITION cycles after "in" goes and stays high

    // Debug
    // output reg [7:0] counter
);

reg [7:0] counter;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter    <= 0;
        start_conv <= 0;
    end else begin
        start_conv <= 1'b0;
        case (counter)
            8'd0:           if (~in) counter <= 8'd1;
            T_ACQUISITION:  begin start_conv <= 1'b1; counter <= 8'd0; end
            default:        counter <= (in) ? counter + 1'b1 : counter <= 8'd1;
        endcase
    end
end

endmodule
