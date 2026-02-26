// Seven-Segment Display Driver
// Time-division multiplexes four digits on the Basys3 seven-segment display.
// Supports decimal digits 0-9 and special characters:
//   4'hA = 'S', 4'hB = 'O', 4'hC = 'C', 4'hD = 'h', 4'hE = '-', 4'hF = blank
//
// seg[6:0] active low: {g, f, e, d, c, b, a}
// an[3:0]  active low: an[3] = leftmost digit

module seg_display (
    input  wire       clk,
    input  wire       rst,
    input  wire       en_mux,      // ~500 Hz mux enable
    input  wire [3:0] digit3,      // leftmost digit
    input  wire [3:0] digit2,
    input  wire [3:0] digit1,
    input  wire [3:0] digit0,      // rightmost digit
    input  wire       dp_en,       // decimal point enable (between digit2 and digit1)
    output reg  [6:0] seg,         // cathode segments (active low)
    output reg        dp,          // decimal point (active low)
    output reg  [3:0] an           // anode enables (active low)
);

    reg [1:0] sel;  // which digit is currently active

    always @(posedge clk) begin
        if (rst)
            sel <= 0;
        else if (en_mux)
            sel <= sel + 1;
    end

    // Mux: select active digit
    reg [3:0] cur_digit;
    always @(*) begin
        case (sel)
            2'd0: begin cur_digit = digit0; an = 4'b1110; end
            2'd1: begin cur_digit = digit1; an = 4'b1101; end
            2'd2: begin cur_digit = digit2; an = 4'b1011; end
            2'd3: begin cur_digit = digit3; an = 4'b0111; end
            default: begin cur_digit = 4'hF; an = 4'b1111; end
        endcase
    end

    // Decimal point: active between digit2 and digit1 position
    // (not used in this design, but available)
    always @(*) begin
        if (dp_en && sel == 2'd2)
            dp = 1'b0;  // active low
        else
            dp = 1'b1;
    end

    // Seven-segment encoding (active low)
    //   seg = {g, f, e, d, c, b, a}
    always @(*) begin
        case (cur_digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0010010; // S (same as 5)
            4'hB: seg = 7'b1000000; // O (same as 0)
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0001011; // h
            4'hE: seg = 7'b0111111; // - (dash)
            4'hF: seg = 7'b1111111; // blank
            default: seg = 7'b1111111;
        endcase
    end

endmodule
