// Clock Divider Module
// Generates enable pulses from the 100MHz master clock:
//   - en_1hz:  1 Hz pulse for timing state durations
//   - en_mux:  ~500 Hz pulse for seven-segment display multiplexing
//   - en_debounce: ~1kHz pulse for debouncer sampling

module clock_divider (
    input  wire clk,        // 100 MHz master clock
    input  wire rst,        // synchronous reset
    output reg  en_1hz,     // 1 Hz enable pulse
    output reg  en_mux,     // ~500 Hz enable pulse
    output reg  en_debounce // ~1 kHz enable pulse
);

    // Counter limits (100 MHz base)
    // 1 Hz:     100_000_000 - 1
    // 500 Hz:   200_000 - 1
    // 1 kHz:    100_000 - 1
    localparam CNT_1HZ_MAX     = 100_000_000 - 1;
    localparam CNT_MUX_MAX     = 200_000 - 1;
    localparam CNT_DEBOUNCE_MAX = 100_000 - 1;

    reg [26:0] cnt_1hz;
    reg [17:0] cnt_mux;
    reg [16:0] cnt_debounce;

    // 1 Hz counter
    always @(posedge clk) begin
        if (rst) begin
            cnt_1hz <= 0;
            en_1hz  <= 0;
        end else if (cnt_1hz == CNT_1HZ_MAX) begin
            cnt_1hz <= 0;
            en_1hz  <= 1;
        end else begin
            cnt_1hz <= cnt_1hz + 1;
            en_1hz  <= 0;
        end
    end

    // ~500 Hz counter
    always @(posedge clk) begin
        if (rst) begin
            cnt_mux <= 0;
            en_mux  <= 0;
        end else if (cnt_mux == CNT_MUX_MAX) begin
            cnt_mux <= 0;
            en_mux  <= 1;
        end else begin
            cnt_mux <= cnt_mux + 1;
            en_mux  <= 0;
        end
    end

    // ~1 kHz counter
    always @(posedge clk) begin
        if (rst) begin
            cnt_debounce <= 0;
            en_debounce  <= 0;
        end else if (cnt_debounce == CNT_DEBOUNCE_MAX) begin
            cnt_debounce <= 0;
            en_debounce  <= 1;
        end else begin
            cnt_debounce <= cnt_debounce + 1;
            en_debounce  <= 0;
        end
    end

endmodule
