module quad (
    input wire          clk,
    input wire          rst_n,
    input wire          A,
    input wire          B,
    output reg [15:0]   count

    // Debug
    // output reg [1:0] state
);


localparam  [7:0]   DEBOUNCE = 8'd100;			// Debounce min transition time: 5us (4000cpr @ 3000rpm), set 1us debounce
localparam [27:0]   COUNT_SCALE = 16'd33554;	// 65536/4000 * 2048
localparam  [1:0]   S00 = 2'b00, S01 = 2'b01, S10 = 2'b10, S11 = 2'b11;
reg [1:0]           state;

reg [1:0] AB_deb, AB_in, AB_in_temp;

// Synchronization
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        AB_in <= 0;
        AB_in_temp <= 0;
    end else begin
        AB_in_temp <= {A,B};
        AB_in <= AB_in_temp;
    end
end

// Debouncing
reg [7:0] deb_cnt;
reg [1:0] AB_prev;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        deb_cnt <= 0;
        AB_prev <= 0;
        AB_deb  <= 0;
    end else begin
        if (AB_in != AB_prev) begin
            deb_cnt <= 0;
            AB_prev <= AB_in;
        end else if (deb_cnt < 16'hFFFF) begin
            deb_cnt <= deb_cnt + 1;
            if (deb_cnt == DEBOUNCE)
                AB_deb <= AB_in;
        end
    end
end

// State machine
reg [11:0] count_temp;
reg dir, tick;  // tick for update
always @ (posedge clk or negedge rst_n) begin
    //Sim
    if (!rst_n) begin
        tick <= 0;
        dir	<= 0;
        count_temp <= 0;
        count <= 16'b0;
        state <= S00;
    end else begin
        case (state)
            S00: if (AB_deb == S10) begin
                    dir <= 1'b1;
                    tick <= 1'b1;
                    state <= S10;
                end else if (AB_deb == S01) begin
                    dir <= 1'b0;
                    tick <= 1'b1;
                    state <= S01;
                end else tick <= 1'b0;
            S10: if (AB_deb == S11) begin
                    dir <= 1'b1;
                    tick <= 1'b1;
                    state <= S11;
                end else if (AB_deb == S00) begin
                    dir <= 1'b0;
                    tick <= 1'b1;
                    state <= S00;
                end else tick <= 1'b0;
            S11: if (AB_deb == S01) begin
                    dir <= 1'b1;
                    tick <= 1'b1;
                    state <= S01;
                end else if (AB_deb == S10) begin
                    dir <= 1'b0;
                    tick <= 1'b1;
                    state <= S10;
                end else tick <= 1'b0;
            S01: if (AB_deb == S00) begin
                    dir <= 1'b1;
                    tick <= 1'b1;
                    state <= S00;
                end else if (AB_deb == S11) begin
                    dir <= 1'b0;
                    tick <= 1'b1;
                    state <= S11;
                end else tick <= 1'b0;
        endcase

        if (tick) begin
            if (dir) begin
                if (count_temp == 12'd3999)
                    count_temp <= 12'd0;
                else
                    count_temp <= count_temp + 1'd1;
            end else begin
                if (count_temp == 12'd0)
                    count_temp <= 12'd3999;
                else
                    count_temp <= count_temp - 1'd1;
            end
        end
        count <= (count_temp * COUNT_SCALE) >> 11;
    end
end

endmodule