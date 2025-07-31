module my_svpwm (
    input wire                  clk,
    input wire                  rst_n,
    input wire                  pwm_en,     // For initial calibration
    input wire         [8:0]    v_amp,      // Must limit because of Deadtime + need time for adc
    input wire signed [15:0]    v_ph_i,    // In polar coords
    input wire signed [15:0]    v_mag_i,
    output reg                  pwm_a, pwm_b, pwm_c,
    output reg                  pwm_an, pwm_bn, pwm_cn

    // Debug
    // output reg [10:0] counter,
    // output reg [2:0]  sector,
    // output reg [15:0] T1, T2, T0d2,
    // output reg [9:0]  Ta, Tb, Tc
);

reg [15:0] mult1;
reg [15:0] mult2;
wire [31:0] mult_o = mult1 * mult2;	// Resusable DSP mult

reg [15:0] v_ph, v_mag;

// Triangle counter
reg signed cnt_dir;
reg [10:0] counter;	// counts to 1024 then counts back down
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        counter <= 0;
        cnt_dir <= 1'b1;
    end else begin
        case (counter)
            11'd0: begin cnt_dir <= 1'b1; counter <= counter + 11'sd1; end
            11'd1024: begin cnt_dir <= 1'b0; counter <= counter - 11'sd1; end
            default: counter <= counter + ((cnt_dir) ? 11'sd1 : -11'sd1);
        endcase
    end
end

// Quarterwave sin table (4 cycle delay)
reg [15:0] i_sin;
wire signed [15:0] o_sin;
sin_lut sin_lut_inst(.clk(clk),.rst_n(rst_n),.i_ph(i_sin),.o_sin(o_sin));

reg [15:0] T0d2,T1,T2;
reg [9:0] Ta,Tb,Tc;

reg [15:0] scaler;

localparam SECTOR_WIDTH = 16'd10923; // 65536 / 6
reg [2:0] sector;
reg [15:0] phase1, phase2;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sector <= 0;
        i_sin <= 0;
        phase1 <= 16'd0;
        phase2 <= 16'd0;
        mult1 <= 16'd0;
        mult2 <= 16'd0;
        scaler <= 0;
        {Ta, Tb, Tc} <= 30'd0;
        {T0d2, T1, T2} <= 48'd0;
        v_ph <= 16'd0;
        v_mag <= 16'd0;
    end else begin
        if (!cnt_dir)
            case (counter)
                11'd20: begin v_ph <= v_ph_i; v_mag <= v_mag_i; end
                11'd19: begin 
                    sector <= ((v_ph * 19'd6) >> 16) + 1;
                    // scaling
                    mult1 <= v_amp;     // (amp * mag) >> 9 
                    mult2 <= v_mag;
                end
                11'd18: begin 
                    phase1 <= (sector * SECTOR_WIDTH) - v_ph;
                    phase2 <= v_ph - ((sector-1) * SECTOR_WIDTH);
                    // scaling
                    scaler <= mult_o >> 9;
                end
                11'd17: begin 
                    i_sin <= phase1;    // then wait 4 cycles
                end
                11'd13: begin
                    i_sin <= phase2;
                    // scaling
                    mult1 <= scaler;
                    mult2 <= o_sin;
                end
                11'd12 : T1 <= mult_o >> 15;    //shift 15 because o_sin is signed 16 bit and only positive values are possible
                11'd9: begin
                    mult1 <= scaler;
                    mult2 <= o_sin;
                end
                11'd8: T2 <= mult_o >> 15;
                11'd7: T0d2 <= 16'h7fff - ((T1+T2) >> 1);   // T0/2
                11'd6: begin
                    case (sector)
                        3'd1: begin
                            Ta <= (T1 + T2 + T0d2) >> 6;
                            Tb <= (T2 + T0d2) >> 6;
                            Tc <= (T0d2) >> 6;
                        end
                        3'd2: begin
                            Ta <= (T1 + T0d2) >> 6;
                            Tb <= (T1 + T2 + T0d2) >> 6;
                            Tc <= (T0d2) >> 6;
                        end
                        3'd3: begin
                            Ta <= (T0d2) >> 6;
                            Tb <= (T1 + T2 + T0d2) >> 6;
                            Tc <= (T2 + T0d2) >> 6;
                        end
                        3'd4: begin
                            Ta <= (T0d2) >> 6;
                            Tb <= (T1 + T0d2) >> 6;
                            Tc <= (T1 + T2 + T0d2) >> 6;
                        end
                        3'd5: begin
                            Ta <= (T2 + T0d2) >> 6;
                            Tb <= (T0d2) >> 6;
                            Tc <= (T1 + T2 + T0d2) >> 6;
                        end
                        3'd6: begin
                            Ta <= (T1 + T2 + T0d2) >> 6;
                            Tb <= (T0d2) >> 6;
                            Tc <= (T1 + T0d2) >> 6;
                        end
                    endcase
                end
                11'd5: begin    // Tabc case delay 2 cycles
                    Ta <= 10'd1023 - Ta;    // 1023 minus because of counter polarity (see center aligned pwm counter)
                    Tb <= 10'd1023 - Tb;
                    Tc <= 10'd1023 - Tc;
                end
            endcase
            
        

    end
end

// Ton=32ns, Tr=50ns, Toff=90ns, Tf=23ns
// Deadtime = 90+23-32 = 82ns -> 10 cycles
localparam [3:0] DEADTIME = 4'd10;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_a <= 1'b0;
        pwm_b <= 1'b0;
        pwm_c <= 1'b0;
        pwm_an <= 1'b0;
        pwm_bn <= 1'b0;
        pwm_cn <= 1'b0;
    end else if (!pwm_en) begin
        pwm_a <= 1'b0;
        pwm_b <= 1'b0;
        pwm_c <= 1'b0;
        pwm_an <= 1'b1;
        pwm_bn <= 1'b1;
        pwm_cn <= 1'b1;
    end else begin
        pwm_a <= (cnt_dir) ? ((counter >= Ta) ? 1'b1 : 1'b0) : ((counter > Ta) ? 1'b1 : 1'b0);
        pwm_b <= (cnt_dir) ? ((counter >= Tb) ? 1'b1 : 1'b0) : ((counter > Tb) ? 1'b1 : 1'b0);
        pwm_c <= (cnt_dir) ? ((counter >= Tc) ? 1'b1 : 1'b0) : ((counter > Tc) ? 1'b1 : 1'b0);

        pwm_an <= ~((cnt_dir) ? ((counter >= Ta - DEADTIME) ? 1'b1 : 1'b0) : ((counter > Ta - DEADTIME) ? 1'b1 : 1'b0));
        pwm_bn <= ~((cnt_dir) ? ((counter >= Tb - DEADTIME) ? 1'b1 : 1'b0) : ((counter > Tb - DEADTIME) ? 1'b1 : 1'b0));
        pwm_cn <= ~((cnt_dir) ? ((counter >= Tc - DEADTIME) ? 1'b1 : 1'b0) : ((counter > Tc - DEADTIME) ? 1'b1 : 1'b0));
    end
end

endmodule