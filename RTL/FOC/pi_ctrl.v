module pi_ctrl (
    input wire                  rst_n,
    input wire                  clk,
    
    input wire                  en_i,
    input wire signed [31:0]    Kp,         // Watch out for signedness
    input wire signed [31:0]    Ki,
    input wire signed [15:0]    ref_i,
    input wire signed [15:0]    feed_i,
    output reg signed [15:0]    out
    
    // Debug
    // output reg [3:0]         stage,
    // output reg signed [31:0] e,
    // output reg signed [31:0] e_i,
    // output reg        [31:0] e_p,
    // output reg signed [41:0] e_int  // Scaled for Ki tuning at higher frequencies
    // output reg        [41:0] e_int_prev,
    // output reg        [1:0]  sat_dir,
    // output reg               accum_e_int
);

// Control
reg [3:0] stage;
wire done;
assign done = (stage == 4'd4);
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) stage <= 0;
    else begin
        case (stage)
            4'd0: if (en_i) stage <= stage + 1;
            default: stage <= done ? 4'd0 : stage + 1;
        endcase
    end
end

reg signed [41:0] e_int, e_int_prev;
reg signed [31:0] e, e_i, e_p;
reg signed [1:0] sat_dir;
reg accum_e_int;

reg signed [63:0] e_i_temp, e_p_temp;

// https://www.embeddedrelated.com/showarticle/121.php
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        e           <= 32'sd0;
        e_i         <= 32'sd0;
        e_p         <= 32'sd0;
        e_int       <= 42'sd0;
        e_int_prev  <= 42'sd0;
        out         <= 16'sd0;
        sat_dir     <= 2'sd0;
        accum_e_int <= 1'd0;
    end else begin
        case (stage)
            4'd0: begin
                {sat_dir, out} <= sat_add(e_p, (e_int >>> 10)) >> 16; //rounding
                e_int_prev <= e_int;
                accum_e_int <= !(((sat_dir > 0) && (e > 0)) || ((sat_dir < 0) && (e < 0))); 
            end
            4'd1: e <= sat_sub($signed({{16{ref_i[15]}}, ref_i}), $signed({{16{feed_i[15]}}, feed_i}));
            // 4'd2: e_i <= sat_mul(Ki, e);
            // 4'd3: begin
            //     e_p <= sat_mul(Kp, e);
            //     if (accum_e_int)
            //         e_int <= sat_add(e_int_prev, e_i);
            // end
            4'd2: begin 
                e_i_temp <= Ki * e;
                e_p_temp <= Kp * e;
            end
            4'd3: begin
                if (e_i_temp > 64'sh7FFFFFFF)
                    e_i <= 32'sh7FFFFFFF;
                else if (e_i_temp < -64'sh80000000)
                    e_i <= 32'sh80000000;    // -2^31
                else
                    e_i <= e_i_temp[31:0];
                
                if (e_p_temp > 64'sh7FFFFFFF)
                    e_p <= 32'sh7FFFFFFF;
                else if (e_p_temp < -64'sh80000000)
                    e_p <= 32'sh80000000;    // -2^31
                else
                    e_p <= e_p_temp[31:0];
            end
            4'd4: begin
                if (accum_e_int) 
                    e_int <= sat_add_int(e_int_prev, e_i);
            end
        endcase

    // e = ref_i - feed_i
    // e_i = Ki*e*dt
    // e_p = Kp*e
    // e_int = e_int + e_i
    // out = e_p + e_int
    end
end


// function [31:0] sat_mul;
//   input signed [31:0] a, b;
//   reg signed [63:0] full_result;
// begin
//   full_result = a * b;
//   if (full_result > 64'sh7FFFFFFF)
//     sat_mul = 32'sh7FFFFFFF;
//   else if (full_result < -64'sh80000000)
//     sat_mul = 32'sh80000000;    // -2^31
//   else
//     sat_mul = full_result[31:0];
// end
// endfunction

function signed [41:0] sat_add_int;
    input signed [41:0] e_int;
    input signed [31:0] e_i;
    
    reg   signed [42:0] sum;
    begin
        sum = e_int + e_i;
        if (sum > 43'sh1FF_FFFF_FFFF)
            sat_add_int = 42'sh1FFFFFFFFFF;
        else if (sum < -43'sh20000000000)
            sat_add_int = 42'sh20000000000;
        else
            sat_add_int = sum[41:0];
    end
endfunction


function signed [33:0] sat_add; //packed 2-MSbit is signed direction of saturation
    input signed [31:0] a, b;
    reg   signed [32:0] sum_ext;
    begin
        sum_ext = a + b;

        if (sum_ext > 33'sh7FFFFFFF)
            sat_add = {2'sd1, 32'sh7FFFFFFF};  // +2^31 - 1
        else if (sum_ext < -33'sh80000000)
            sat_add = {-2'sd1, 32'sh80000000}; // -2^31 (+1 or not?????)
        else
            sat_add = {2'd0, sum_ext[31:0]};
    end
endfunction

function signed [31:0] sat_sub;
    input signed [31:0] a, b;
    reg   signed [32:0] diff_ext;
    begin
        diff_ext = a - b;

        if (diff_ext > 33'sh7FFFFFFF)
            sat_sub = 32'sh7FFFFFFF;
        else if (diff_ext < -33'sh80000000)
            sat_sub = 32'sh80000000;
        else
            sat_sub = diff_ext[31:0];
    end
endfunction

endmodule


