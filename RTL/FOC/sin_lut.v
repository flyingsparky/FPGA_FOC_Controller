// Quarter-wave sin table
// Reference: https://zipcpu.com/dsp/2017/08/26/quarterwave.html
module sin_lut (
    input wire                  clk,
    input wire                  rst_n,
    input wire        [15:0]    i_ph,
    output reg signed [15:0]    o_sin
);

reg [13:0] index;
reg [15:0] tbl_temp;
reg [1:0] negate;

reg [15:0] tbl [0:((1<<14)-1)];

initial	$readmemh("sin_lut.hex", tbl);  //generated using cpp code (file path is finicky need tb in same folder idk)

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_sin <= 0;
        negate <= 0;
        tbl_temp <= 0;
        index <= 0;
    end else begin
        /*  Only to illustrate logic, but may not synthesize ROM correctly due to operations on index and output
        case({i_ph[15:14]})
        2'b00:	o_sin <=  tbl[ i_ph[13:0]];
        2'b01:	o_sin <=  tbl[~i_ph[13:0]];	//index table in reversed order
        2'b10:	o_sin <= -tbl[ i_ph[13:0]];
        2'b11:	o_sin <= -tbl[~i_ph[13:0]];
        endcase
        */

        // pipeline scheduling
        negate[0] <= i_ph[15];
        negate[1] <= negate[0];

        index <= i_ph[14] ? ~i_ph[13:0] : i_ph[13:0];
        tbl_temp <= tbl[index];
        o_sin <= negate[1] ? ~tbl_temp : tbl_temp;
    end

end

endmodule