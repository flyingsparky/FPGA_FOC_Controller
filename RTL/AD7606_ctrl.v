// Modified from https://github.com/maxs-well/ad7606-driver-verilog
// Adapted for timing requirements
module AD7606_ctrl #(
    parameter       RANGE_10V = 0,
    parameter [3:0] T2        = 4'd3,     // Min CONVST low time 25ns
    parameter [3:0] T14       = 4'd5,     // Time after RD low to read output 30ns
    parameter [3:0] T10       = 4'd6,     // RD min low pulse width 30ns
    parameter [3:0] T11       = 4'd3,     // RD min high pulse width 15ns
    parameter       OS        = 3'd1      // Oversample by 2
) (
    input wire              clk,
    input wire              rst_n,
    input wire              en,
    input wire              start,
    output reg              done,
    output reg [15:0]       ch1,
    output reg [15:0]       ch2,
    output reg [15:0]       ch3,
    // output reg [15:0]    ch4,
    // output reg [15:0]    ch5,
    // output reg [15:0]    ch6,
    // output reg [15:0]    ch7,
    // output reg [15:0]    ch8,

    // phy interface and signals
    input wire              busy,
    input wire              fdata,   // Unused
    input wire [15:0]       cvtData,
    output reg              cs,
    output reg              rd,
    output wire             cvtA,
    output wire             cvtB,
    output wire             range,
    output reg              phy_rst,
    output reg [2:0]        os
);

localparam
    IDLE      = 4'd0,
    CVT       = 4'd1,
    BUSY      = 4'd2,
    RD_ST     = 4'd3,
    GET_DATA  = 4'd4,
    DONE      = 4'd5,
    WAIT_TIME = 4'd6;

reg         update;
reg         cvtA_r;
reg [3:0]   state;
reg [3:0]   nxt_state;
reg [3:0]   cnt;
reg [3:0]   cnt1;
wire [3:0]  ch_num;

assign cvtA = cvtA_r;
assign cvtB = cvtA_r;
assign ch_num = 4'd3;

assign range = (RANGE_10V == 1) ? 1'b1 : 1'b0;

always @ (posedge clk) begin
    if (state == CVT && cnt <= T2 - 4'd1) begin
        cvtA_r <= 'b0;
    end else begin
        cvtA_r <= 1'b1;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
end

always @ (state, busy, start, en, update) begin
    nxt_state <= state;
    case (state)
        IDLE: begin
            if (!busy && start && en)
                nxt_state <= CVT;
        end
        CVT: begin
            if (busy)
                nxt_state <= BUSY;
        end
        BUSY: begin
            if (!busy)
                nxt_state <= RD_ST;
        end
        RD_ST: begin
            nxt_state <= GET_DATA;
        end
        GET_DATA: begin
            if (update)
                nxt_state <= DONE;
        end
        DONE:
            nxt_state <= IDLE;
        default:
            nxt_state <= IDLE;
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done    <= 'b0;
        cs      <= 1'b1;
        rd      <= 1'b1;
        update  <= 'd0;
        os      <= OS;

        ch1     <= 'd0;
        ch2     <= 'd0;
        ch3     <= 'd0;
        // ch4  <= 'd0;
        // ch5  <= 'd0;
        // ch6  <= 'd0;
        // ch7  <= 'd0;
        // ch8  <= 'd0;
        phy_rst <= 1'b1;
        cnt     <= 'd0;
        cnt1    <= 'd0;
    end else begin
        case (state)
            IDLE: begin
                done <= 'b0;
                cs <= 1'b1;
                rd <= 1'b1;
                update <= 'd0;

                phy_rst <= 'd0;
                cnt <= 'd0;
            end

            CVT: begin
                if (cnt <= T2 - 4'd1)
                    cnt <= cnt + 4'd1;
            end

            RD_ST: begin
                cs <= 1'b0;
                cnt <= 'd0;
                cnt1 <= 0;
            end

            GET_DATA: begin
                if (!rd) begin
                    if (cnt1 < T14 - 4'd1)
                        cnt1 <= cnt1 + 1'b1;
                    else if (cnt1 < T10 - 4'd1) begin
                        case (cnt)
                            4'd0: ch1 <= cvtData;
                            4'd1: ch2 <= cvtData;
                            4'd2: ch3 <= cvtData;
                            // 4'd3: ch4 <= cvtData;
                            // 4'd4: ch5 <= cvtData;
                            // 4'd5: ch6 <= cvtData;
                            // 4'd6: ch7 <= cvtData;
                            // 4'd7: ch8 <= cvtData;
                            default: ;
                        endcase
                        cnt1 <= cnt1 + 1'b1;
                    end else begin
                        rd <= 1'b1;
                        cnt <= cnt + 1'b1;
                        cnt1 <= 0;
                    end
                end else begin
                    if (cnt1 < T11 - 4'd1)
                        cnt1 <= cnt1 + 4'd1;
                    else begin
                        rd <= 1'b0;
                        cnt1 <= 0;
                    end
                end

                if (rd && (cnt >= ch_num))
                    update <= 1'b1;
                else
                    update <= 1'b0;
            end

            DONE:
                done <= 1'b1;
            default: ;
        endcase
    end
end

endmodule
