module foc_top # (
    parameter [31:0] INIT_TIME  = 32'd100000000,     // (~1s at 102.4Mhz)
    parameter [8:0]  MAX_AMP    = 9'd420,            // Must limit because of Deadtime wraparound + need time for adc
    parameter        AXI_TUNE   = 1'b1,              // Tune PI with JTAG-AXI Master interface
    parameter [31:0] Kp_par     = 32'h200000,
    parameter [31:0] Ki_par     = 32'h12000,
    parameter [7:0]  POLEPAIRS  = 8'd4,
    parameter        ANG_INV    = 1
) (
    // Reset & clock
    input wire                  clk,
    input wire                  rst_n,
    // Calibration done
    input wire                  calib_done,
    // Mechanical angle
    input wire          [15:0]  psi_raw,
    // PI Tuning Kp/Ki inputs
    input wire          [31:0]  Kp_tune, Ki_tune,
    // Input commands
    input wire signed   [15:0]  id, iq,
    // Current readings for feedback
    input wire signed   [15:0]  ia, ib, ic,
    // Inverter PWM
    output wire                 pwm_a, pwm_b, pwm_c,
    output wire                 pwm_an, pwm_bn, pwm_cn

    // Debug
    // output wire signed   [15:0]  Vd, Vq,
    // output wire signed   [15:0]  id_fb, iq_fb,  // Feedback i_d/q
    // output wire          [15:0]  phase,
    // output reg           [15:0]  phi,
    // output reg                   initialized,
    // output wire signed   [31:0]  e,
    // output wire signed   [31:0]  e_i,
    // output wire signed   [41:0]  e_int
);

wire [31:0] Kp, Ki;
assign Kp = (AXI_TUNE) ? Kp_tune : Kp_par;
assign Ki = (AXI_TUNE) ? Ki_tune : Ki_par;

wire        [15:0]  mag;
wire        [15:0]  psi;                // Mechanical angle
reg         [15:0]  phi;                // Electrical angle
wire        [15:0]  theta;              // Time invariant vector angle (in d-q)
wire        [15:0]  phase;              // Time variant vector angle (in alpha-beta)
wire signed [15:0]  i_alpha, i_beta;
wire signed [15:0]  id_fb, iq_fb;       // Feedback i_d/q
wire signed [15:0]  Vd, Vq;

wire [15:0] mag_o, phase_o;     // Output from topolar and inv_park, disconnected when initializing
reg  [15:0] mag_init, phase_init;
reg  [15:0] psi_offset;

reg initialized;
reg [31:0] init_counter;

assign mag   = (initialized) ? mag_o : mag_init;
assign phase = (initialized) ? phase_o : phase_init;
assign psi   = (ANG_INV) ? (psi_offset - psi_raw) : (psi_raw - psi_offset);

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        initialized  <= 0;
        init_counter <= 0;
        mag_init     <= 0;
        phase_init   <= 0;
        psi_offset   <= 0;
        phi          <= 0;
    end else if (calib_done) begin
        mag_init <= (25'hffff * MAX_AMP) >>> 9;
        phi <= {8'h0, POLEPAIRS} * psi;
        if (!initialized) begin
            init_counter <= init_counter + 1;
            if (init_counter == INIT_TIME) begin
                psi_offset <= psi_raw;
                initialized <= 1'b1;
            end
        end
    end
end

my_svpwm my_svpwm_inst (
    .rst_n   (rst_n),
    .clk     (clk),
    .pwm_en  (calib_done),
    .v_amp   (MAX_AMP),
    .v_ph_i  (phase),
    .v_mag_i (mag),
    .pwm_a   (pwm_a),
    .pwm_b   (pwm_b),
    .pwm_c   (pwm_c),
    .pwm_an  (pwm_an),
    .pwm_bn  (pwm_bn),
    .pwm_cn  (pwm_cn)
);

clarke clarke_inst (
    .rst_n  (rst_n),
    .clk    (clk),
    .ia     (ia),
    .ib     (ib),  // ic unused since two currents is enough
    .alpha  (i_alpha),
    .beta   (i_beta)
);

park park_inst (
    .rst_n  (rst_n),
    .clk    (clk),
    .phi    (phi),
    .alpha  (i_alpha),
    .beta   (i_beta),
    .id     (id_fb),
    .iq     (iq_fb)
);

topolar topolar_inst (
    .i_reset (~rst_n),
    .i_clk  (clk),
    .i_ce   (rst_n),
    .i_xval (Vd),
    .i_yval (Vq),
    .o_mag  (mag_o),
    .o_phase(theta),
    .i_aux  (),
    .o_aux  ()
);

inv_park inv_park_inst (
    .rst_n  (rst_n),
    .clk    (clk),
    .theta  (theta),
    .phi    (phi),
    .phase  (phase_o)
);

pi_ctrl pi_ctrl_d (
    .rst_n  (rst_n),
    .clk    (clk),
    .en_i   (initialized),
    .ref_i  (id),
    .feed_i (id_fb),
    .Kp     (Kp),
    .Ki     (Ki),
    .out    (Vd)
);

pi_ctrl pi_ctrl_q (
    .rst_n  (rst_n),
    .clk    (clk),
    .en_i   (initialized),
    .ref_i  (iq),
    .feed_i (iq_fb),
    .Kp     (Kp),
    .Ki     (Ki),
    .out    (Vq)

    // Debug
    // .e      (e),
    // .e_i    (e_i),
    // .e_int  (e_int)
);

endmodule
