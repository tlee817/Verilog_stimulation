// Vending Machine Top Module
// Basys3 FPGA pin mapping

module vending_top (
    input  wire       clk,          // 100 MHz (W5)
    // Buttons (active high on Basys3)
    input  wire       btn_reset,    // Center button (U18)
    input  wire       btn_confirm,  // Left button (W19)
    input  wire       btn_nickel,   // Up button (T17)
    input  wire       btn_dime,     // Right button (T18)
    input  wire       btn_quarter,  // Down button (U17)
    // Switches
    input  wire       sw_sel0,      // SW0 - item select bit 0 (V17)
    input  wire       sw_sel1,      // SW1 - item select bit 1 (V16)
    input  wire       sw_restock,   // SW2 - restock mode (W16)
    // Seven-segment display
    output wire [6:0] seg,          // cathode segments (active low)
    output wire       dp,           // decimal point (active low)
    output wire [3:0] an,           // anode enables (active low)
    // LEDs
    output wire [3:0] led           // item dispense LEDs (LD0-LD3)
);

    // Internal signals
    wire en_1hz, en_mux, en_debounce;
    wire rst;
    wire db_confirm, db_nickel, db_dime, db_quarter;
    wire db_sel0, db_sel1, db_restock;
    wire pulse_confirm, pulse_nickel, pulse_dime, pulse_quarter;
    wire [3:0] digit3, digit2, digit1, digit0;

    // Reset: use debounced button pulse
    wire rst_pulse;

    // Clock divider
    clock_divider u_clkdiv (
        .clk        (clk),
        .rst        (rst),
        .en_1hz     (en_1hz),
        .en_mux     (en_mux),
        .en_debounce(en_debounce)
    );

    // Debouncers for buttons (use pulse output)
    debouncer u_db_reset (
        .clk(clk), .rst(1'b0), .en_sample(en_debounce),
        .raw_in(btn_reset), .db_level(), .db_pulse(rst_pulse)
    );
    assign rst = rst_pulse;

    debouncer u_db_confirm (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(btn_confirm), .db_level(db_confirm), .db_pulse(pulse_confirm)
    );
    debouncer u_db_nickel (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(btn_nickel), .db_level(db_nickel), .db_pulse(pulse_nickel)
    );
    debouncer u_db_dime (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(btn_dime), .db_level(db_dime), .db_pulse(pulse_dime)
    );
    debouncer u_db_quarter (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(btn_quarter), .db_level(db_quarter), .db_pulse(pulse_quarter)
    );

    // Debouncers for switches (use level output)
    debouncer u_db_sel0 (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(sw_sel0), .db_level(db_sel0), .db_pulse()
    );
    debouncer u_db_sel1 (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(sw_sel1), .db_level(db_sel1), .db_pulse()
    );
    debouncer u_db_restock (
        .clk(clk), .rst(rst), .en_sample(en_debounce),
        .raw_in(sw_restock), .db_level(db_restock), .db_pulse()
    );

    // FSM Controller
    fsm_controller u_fsm (
        .clk        (clk),
        .rst        (rst),
        .en_1hz     (en_1hz),
        .btn_confirm(pulse_confirm),
        .btn_nickel (pulse_nickel),
        .btn_dime   (pulse_dime),
        .btn_quarter(pulse_quarter),
        .sw_item    ({db_sel1, db_sel0}),
        .sw_restock (db_restock),
        .digit3     (digit3),
        .digit2     (digit2),
        .digit1     (digit1),
        .digit0     (digit0),
        .item_leds  (led)
    );

    // Seven-Segment Display Driver
    seg_display u_seg (
        .clk    (clk),
        .rst    (rst),
        .en_mux (en_mux),
        .digit3 (digit3),
        .digit2 (digit2),
        .digit1 (digit1),
        .digit0 (digit0),
        .dp_en  (1'b0),
        .seg    (seg),
        .dp     (dp),
        .an     (an)
    );

endmodule
