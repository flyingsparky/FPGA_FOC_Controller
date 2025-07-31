module park (
    input wire                  clk,
    input wire                  rst_n,
    input wire        [15:0]    phi,       // actual electrical angle
    input wire signed [15:0]    alpha,
    input wire signed [15:0]    beta,
    output reg signed [15:0]    id,
    output reg signed [15:0]    iq

    // Debug
    // output reg [2:0] counter,
    // output reg signed [31:0] temp1, temp2,
);

// Quarterwave sin table (4 cycle delay)
reg [15:0] i_sin;
wire signed [15:0] o_sin;
sin_lut sin_lut_inst(.clk(clk),.rst_n(rst_n),.i_ph(i_sin),.o_sin(o_sin));

// Resusable DSP mult
reg  signed [15:0] mult1;
reg  signed [15:0] mult2;
wire signed [31:0] mult_o1 = mult1 * mult2;

reg  signed [15:0] mult3;
reg  signed [15:0] mult4;
wire signed [31:0] mult_o2 = mult3 * mult4;

reg  signed [16:0] temp1, temp2;
reg  signed [16:0] id_temp, iq_temp;

reg [2:0] counter;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        i_sin <= 0;
        mult1 <= 0;
        mult2 <= 0;
        mult3 <= 0;
        mult4 <= 0;
        temp1 <= 0;
        temp2 <= 0;
        id_temp <= 0;
        iq_temp <= 0;
        id <= 0;
        iq <= 0;
    end else begin
        counter <= counter + 3'd1;
        case (counter)
            3'd0: begin
                i_sin <= phi;
                //pipelined
                temp1 <= mult_o1 >>> 15;	// beta * sin
                temp2 <= mult_o2 >>> 15;	// alpha * sin
                mult2 <= o_sin;				// cos
                mult4 <= o_sin;
            end
            3'd1: begin
                i_sin <= phi + 16'h3fff;				// + pi/2
                //pipelined
                id_temp <= (mult_o2 >>> 15) + temp1;	// alpha*cos + beta*sin
                iq_temp <= -temp2 + (mult_o1 >>> 15);	// -alpha*sin + beta*cos
            end
            3'd4: begin
                mult1 <= beta;
                mult2 <= o_sin;
                mult3 <= alpha;
                mult4 <= o_sin;
                counter <= 3'd0;
            end
        endcase
        if (id_temp > 17'sh7fff)
            id <= 16'h7fff;
        else if (id_temp < -17'sh7fff)
            id <= -16'sh7fff;
        else
            id <= id_temp;

        if (iq_temp > 17'sh7fff)
            iq <= 16'h7fff;
        else if (iq_temp < -17'sh7fff)
            iq <= -16'sh7fff;
        else
            iq <= iq_temp;
    end
end

endmodule