module inv_park (
    input wire          clk,
    input wire          rst_n,
    input wire [15:0]   theta,
    input wire [15:0]   phi,
    output reg [15:0]   phase
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        phase <= 0;
    else
        phase <= theta + phi;  // Inverse Park transform in polar form is just adding actual electrical angle
end

endmodule
