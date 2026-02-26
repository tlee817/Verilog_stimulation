// Debouncer Module
// Samples the input at the en_sample rate to filter noise.
// Outputs:
//   - db_level: debounced level (for switches)
//   - db_pulse: single-cycle pulse on rising edge (for buttons)

module debouncer (
    input  wire clk,
    input  wire rst,
    input  wire en_sample,   // sampling enable pulse (~1 kHz)
    input  wire raw_in,      // raw button/switch input
    output wire db_level,    // debounced level
    output wire db_pulse     // single-cycle rising-edge pulse
);

    // Two-stage synchronizer for metastability
    reg sync_0, sync_1;
    always @(posedge clk) begin
        if (rst) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end else begin
            sync_0 <= raw_in;
            sync_1 <= sync_0;
        end
    end

    // Debounce: require stable input for multiple samples
    reg [3:0] count;
    reg       db_reg;

    always @(posedge clk) begin
        if (rst) begin
            count  <= 0;
            db_reg <= 0;
        end else if (en_sample) begin
            if (sync_1 != db_reg) begin
                count <= count + 1;
                if (count == 4'd10) begin
                    db_reg <= sync_1;
                    count  <= 0;
                end
            end else begin
                count <= 0;
            end
        end
    end

    assign db_level = db_reg;

    // Edge detection: single-cycle pulse on rising edge of db_reg
    reg db_prev;
    always @(posedge clk) begin
        if (rst)
            db_prev <= 0;
        else
            db_prev <= db_reg;
    end

    assign db_pulse = db_reg & ~db_prev;

endmodule
