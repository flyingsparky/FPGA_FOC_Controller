/*
    What to change with clk freq:
    T2            - ADC min CONVST low time
    cnt           - iq command time
    conv_counter  - conversion time counter for calibration
    INIT_TIME     - time for rotor alignment
    T_ACQUISITION - acquisition time after lower mosfet turns on
    Ki            - scale with clk
    DEADTIME      = MOSFET deadtime to avoid cross-conduction
*/

module hardware_top (
    // Reset & clock
    input  wire         clk,
    input  wire         rst_n,

    // ABZ Encoder (Z not used for not)
    input  wire         A, B,

    // ADC connections
    input  wire [31:0]  Kp_tune, Ki_tune,  // Tune PI with JTAG-AXI Master interface
    input  wire         adc_busy_i,
    input  wire         adc_fdata_i,
    input  wire [15:0]  adc_cvtData_i,
    output wire         adc_cs_o,
    output wire         adc_rd_o,
    output wire         adc_cvtA_o,
    output wire         adc_cvtB_o,
    output wire         adc_range_o,
    output wire [2:0]   adc_os_o,
    output wire         adc_phy_rst_o,

    // Inverter PWM
    output wire         pwm_a, pwm_b, pwm_c,
    output wire         pwm_an, pwm_bn, pwm_cn

    // Debug
    // output wire         [15:0] ia, ib, ic,
    // output wire         [15:0] psi_raw,
    // output wire signed  [15:0] id, iq, 
    // output wire signed  [15:0] Vd, Vq,
    // output wire signed  [15:0] id_fb, iq_fb,  // Feedback i_d/q
    // output wire         [15:0] phase,
    // output wire         [15:0] phi,
    // output reg                  calib_done,
    // output wire                 initialized,
    // output wire signed  [31:0] e,
    // output wire signed  [31:0] e_i,
    // output wire signed  [41:0] e_int
);

// Input commands: q - torque component, d - aligns with rotor flux (set to 0)
wire signed [15:0] id, iq;  // Scaled to +-10A range (4A rated but 14A max, +-13107 range for id)

// Test command, alternating directions
reg [27:0] cnt;
always @(posedge clk or negedge rst_n)
    if (!rst_n)
        cnt <= 0;
    else
        cnt <= cnt + 1;

reg [15:0] iq_temp;
assign id = 16'sd0;
assign iq = iq_temp;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iq_temp <= 16'sd0;
    end else begin
        if (cnt[27])
            iq_temp <= 16'sd400;
        else
            iq_temp <= -16'sd400;
    end
end

// ADC bias calibration
wire start_conv_hold, start_conv;
reg start_conv_calib;
wire adc_done;
reg calib_done;
reg [12:0] adc_calib_counter;
reg [10:0] conv_counter;
reg signed [27:0] adc_sum_a, adc_sum_b, adc_sum_c;  // Sum 4096 samples
reg signed [15:0] adc_a_bias, adc_b_bias, adc_c_bias;

assign start_conv = (calib_done) ? start_conv_hold : start_conv_calib;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calib_done          <= 0;
        adc_calib_counter   <= 0;
        conv_counter        <= 0;
        adc_sum_a           <= 0;
        adc_sum_b           <= 0;
        adc_sum_c           <= 0;
        adc_a_bias          <= 0;
        adc_b_bias          <= 0;
        adc_c_bias          <= 0;
    end else begin
        
        if (conv_counter >= 11'd1500) begin
            start_conv_calib <= 1'b1;
            conv_counter <= 0;
        end else begin
            start_conv_calib <= 1'b0;
            conv_counter <= conv_counter + 1'b1;
        end
        
        if (~adc_calib_counter[12]) begin
            if (adc_done) begin
                adc_sum_a <= adc_sum_a + adc_a;
                adc_sum_b <= adc_sum_b + adc_b;
                adc_sum_c <= adc_sum_c + adc_c;
                adc_calib_counter <= adc_calib_counter + 1'd1;
            end
        end else begin
            calib_done <= 1'b1;
            adc_a_bias <= adc_sum_a >>> 12;
            adc_b_bias <= adc_sum_b >>> 12;
            adc_c_bias <= adc_sum_c >>> 12;
        end
    end
end

// Mechanical angle pre-init
wire [15:0] psi_raw;
// Current readings for feedback
wire signed [15:0] ia, ib, ic;
wire signed [15:0] adc_a, adc_b, adc_c;

foc_top foc_top_inst(
    .clk            (clk),
    .rst_n          (rst_n),
    .calib_done     (calib_done),
    .psi_raw        (psi_raw),
    .Kp_tune        (Kp_tune),
    .Ki_tune        (Ki_tune),
    .id             (id),
    .iq             (iq),
    .ia             (ia),
    .ib             (ib),
    .ic             (ic),
    .pwm_a          (pwm_a),
    .pwm_b          (pwm_b),
    .pwm_c          (pwm_c),
    .pwm_an         (pwm_an),
    .pwm_bn         (pwm_bn),
    .pwm_cn         (pwm_cn)
    // Debug
    // .Vd             (Vd),
    // .Vq             (Vq),
    // .id_fb          (id_fb),
    // .iq_fb          (iq_fb),
    // .phase          (phase),
    // .phi            (phi),
    // .initialized    (initialized),
    // .e              (e),
    // .e_i            (e_i),
    // .e_int          (e_int)
);

quad quad_inst(
    .clk            (clk),
    .rst_n          (rst_n),
    .A              (A),
    .B              (B),
    .count          (psi_raw)
);

reg adc_busy;
reg [15:0] adc_cvtData;
AD7606_ctrl AD7606_ctrl_inst(
    .clk            (clk),
    .rst_n          (rst_n),
    .en             (rst_n),
    .start          (start_conv),
    .done           (adc_done),
    .ch1            (adc_a),
    .ch2            (adc_b),
    .ch3            (adc_c),
//    .ch4(),
//    .ch5(),
//    .ch6(),
//    .ch7(),
//    .ch8(),
    .busy           (adc_busy),
    .fdata          (),  // Unused for now
    .cvtData        (adc_cvtData),
    .cs             (adc_cs_o),
    .rd             (adc_rd_o),
    .cvtA           (adc_cvtA_o),
    .cvtB           (adc_cvtB_o),
    .range          (adc_range_o),
    .os             (adc_os_o),
    .phy_rst        (adc_phy_rst_o)
);

// Start ADC convertion after all pwm_xn held high for at least acquisition time
wire adc_start_in;
assign adc_start_in = pwm_an & pwm_bn & pwm_cn;

adc_start adc_start_inst(
    .rst_n          (rst_n),
    .clk            (clk),
    .in             (adc_start_in),
    .start_conv     (start_conv_hold)
);

// Specific to BOOSTXL-DRV8305 board
// OP amp output voltage is 0.95-2.35V for -10A to 10A range
// minus 1.65 and scale range to +-0.7V
reg signed [19:0] ia_temp1, ib_temp1, ic_temp1;
localparam adc_scale = 34'sd58514;  // 5/0.7*2^13

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ia_temp1 <= 0;
        ib_temp1 <= 0;
        ic_temp1 <= 0;
    end else begin
        if (adc_done) begin
            ia_temp1 <= ($signed(adc_a - adc_a_bias) * $signed(adc_scale)) >>> 13;
            ib_temp1 <= ($signed(adc_b - adc_b_bias) * $signed(adc_scale)) >>> 13;
            ic_temp1 <= ($signed(adc_c - adc_c_bias) * $signed(adc_scale)) >>> 13;
        end
    end
end

assign ia = (ia_temp1 > 20'sh7fff)  ?  16'sh7fff :
            (ia_temp1 < -20'sh7fff) ? -16'sh7fff : ia_temp1[15:0];
assign ib = (ib_temp1 > 20'sh7fff)  ?  16'sh7fff :
            (ib_temp1 < -20'sh7fff) ? -16'sh7fff : ib_temp1[15:0];
assign ic = (ic_temp1 > 20'sh7fff)  ?  16'sh7fff :
            (ic_temp1 < -20'sh7fff) ? -16'sh7fff : ic_temp1[15:0];


// Input synchronization
reg          adc_busy_sync;
reg  [15:0]  adc_cvtData_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_busy_sync    <= 1'b0;
        adc_busy         <= 1'b0;
        adc_cvtData_sync <= 16'd0;
        adc_cvtData      <= 16'd0;
    end else begin
        // adc_busy
        adc_busy_sync    <= adc_busy_i;
        adc_busy         <= adc_busy_sync;
        // adc_cvtData
        adc_cvtData_sync <= adc_cvtData_i;
        adc_cvtData      <= adc_cvtData_sync;
    end
end

endmodule
