module fsm_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       en_1hz,
    input  wire       btn_confirm,
    input  wire       btn_nickel,
    input  wire       btn_dime,
    input  wire       btn_quarter,
    input  wire [1:0] sw_item,
    input  wire       sw_restock,
    output reg  [3:0] digit3,
    output reg  [3:0] digit2,
    output reg  [3:0] digit1,
    output reg  [3:0] digit0,
    output reg  [3:0] item_leds
);

    localparam S_IDLE       = 3'd0;
    localparam S_SOLD_OUT   = 3'd1;
    localparam S_SHOW_PRICE = 3'd2;
    localparam S_INSERT     = 3'd3;
    localparam S_DISPENSE   = 3'd4;
    localparam S_SHOW_CHG   = 3'd5;

    reg [2:0] state, next_state;

    function [6:0] get_price;
        input [1:0] item;
        case (item)
            2'd0: get_price = 7'd25;
            2'd1: get_price = 7'd50;
            2'd2: get_price = 7'd75;
            2'd3: get_price = 7'd95;
        endcase
    endfunction

    reg [6:0] balance;
    reg [6:0] price;
    reg [1:0] sel_item;
    reg [6:0] change;
    reg [2:0] timer;
    reg [2:0] stock_0, stock_1, stock_2, stock_3;

    // Read stock with proper sensitivity (avoid function in continuous assign)
    reg [2:0] cur_stock;
    always @(*) begin
        case (sw_item)
            2'd0: cur_stock = stock_0;
            2'd1: cur_stock = stock_1;
            2'd2: cur_stock = stock_2;
            2'd3: cur_stock = stock_3;
        endcase
    end

    reg [2:0] sel_stock;
    always @(*) begin
        case (sel_item)
            2'd0: sel_stock = stock_0;
            2'd1: sel_stock = stock_1;
            2'd2: sel_stock = stock_2;
            2'd3: sel_stock = stock_3;
        endcase
    end

    function [7:0] to_bcd;
        input [6:0] val;
        begin
            to_bcd[7:4] = val / 10;
            to_bcd[3:0] = val % 10;
        end
    endfunction

    // State register
    always @(posedge clk) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    // Timer-based transitions trigger on timer==0 (one cycle after
    // the en_1hz tick that decremented timer to 0). This avoids
    // race conditions between en_1hz and the timer update.
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (!sw_restock && btn_confirm) begin
                    if (cur_stock == 0)
                        next_state = S_SOLD_OUT;
                    else
                        next_state = S_SHOW_PRICE;
                end
            end
            S_SOLD_OUT: begin
                if (timer == 0)
                    next_state = S_IDLE;
            end
            S_SHOW_PRICE: begin
                if (timer == 0)
                    next_state = S_INSERT;
            end
            S_INSERT: begin
                if (balance >= price)
                    next_state = S_DISPENSE;
            end
            S_DISPENSE: begin
                if (timer == 0) begin
                    if (change > 0)
                        next_state = S_SHOW_CHG;
                    else
                        next_state = S_IDLE;
                end
            end
            S_SHOW_CHG: begin
                if (timer == 0)
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Datapath
    always @(posedge clk) begin
        if (rst) begin
            balance   <= 0;
            price     <= 0;
            sel_item  <= 0;
            change    <= 0;
            timer     <= 0;
            item_leds <= 4'b0000;
            stock_0   <= 3'd5;
            stock_1   <= 3'd5;
            stock_2   <= 3'd5;
            stock_3   <= 3'd5;
        end else begin
            case (state)
                S_IDLE: begin
                    balance   <= 0;
                    change    <= 0;
                    item_leds <= 4'b0000;
                    if (sw_restock) begin
                        if (btn_confirm && cur_stock < 3'd5) begin
                            case (sw_item)
                                2'd0: stock_0 <= stock_0 + 1;
                                2'd1: stock_1 <= stock_1 + 1;
                                2'd2: stock_2 <= stock_2 + 1;
                                2'd3: stock_3 <= stock_3 + 1;
                            endcase
                        end
                    end else if (btn_confirm) begin
                        sel_item <= sw_item;
                        price    <= get_price(sw_item);
                        timer    <= 3'd1;
                    end
                end

                S_SOLD_OUT: begin
                    if (en_1hz && timer > 0)
                        timer <= timer - 1;
                end

                S_SHOW_PRICE: begin
                    if (en_1hz && timer > 0)
                        timer <= timer - 1;
                end

                S_INSERT: begin
                    if (btn_nickel && balance <= 7'd94)
                        balance <= balance + 7'd5;
                    else if (btn_dime && balance <= 7'd89)
                        balance <= balance + 7'd10;
                    else if (btn_quarter && balance <= 7'd74)
                        balance <= balance + 7'd25;
                end

                S_DISPENSE: begin
                    item_leds <= (4'b0001 << sel_item);
                    if (en_1hz && timer > 0)
                        timer <= timer - 1;
                end

                S_SHOW_CHG: begin
                    item_leds <= 4'b0000;
                    if (en_1hz && timer > 0)
                        timer <= timer - 1;
                end

                default: ;
            endcase

            // Transition actions
            if (state == S_INSERT && next_state == S_DISPENSE) begin
                timer  <= 3'd2;
                change <= balance - price;
                case (sel_item)
                    2'd0: stock_0 <= stock_0 - 1;
                    2'd1: stock_1 <= stock_1 - 1;
                    2'd2: stock_2 <= stock_2 - 1;
                    2'd3: stock_3 <= stock_3 - 1;
                endcase
            end

            if (state == S_DISPENSE && next_state == S_SHOW_CHG)
                timer <= 3'd2;
        end
    end

    // Display output
    wire [7:0] bcd_balance = to_bcd(balance);
    wire [7:0] bcd_price   = to_bcd(price);
    wire [7:0] bcd_change  = to_bcd(change);
    wire [7:0] bcd_stock   = to_bcd({4'b0, cur_stock});

    always @(*) begin
        case (state)
            S_IDLE: begin
                if (sw_restock) begin
                    case (sw_item)
                        2'd0: digit3 = 4'hA;
                        2'd1: digit3 = 4'h8;
                        2'd2: digit3 = 4'hC;
                        2'd3: digit3 = 4'hD;
                    endcase
                    digit2 = 4'hE;
                    digit1 = 4'hF;
                    digit0 = bcd_stock[3:0];
                end else begin
                    digit3 = 4'h0;
                    digit2 = 4'h0;
                    digit1 = 4'h0;
                    digit0 = 4'h0;
                end
            end
            S_SOLD_OUT: begin
                digit3 = 4'hA;
                digit2 = 4'hB;
                digit1 = 4'hE;
                digit0 = 4'hE;
            end
            S_SHOW_PRICE: begin
                digit3 = 4'hF;
                digit2 = 4'hF;
                digit1 = bcd_price[7:4];
                digit0 = bcd_price[3:0];
            end
            S_INSERT: begin
                digit3 = 4'hF;
                digit2 = 4'hF;
                digit1 = bcd_balance[7:4];
                digit0 = bcd_balance[3:0];
            end
            S_DISPENSE: begin
                digit3 = 4'hE;
                digit2 = 4'hE;
                digit1 = 4'hE;
                digit0 = 4'hE;
            end
            S_SHOW_CHG: begin
                digit3 = 4'hC;
                digit2 = 4'hD;
                digit1 = bcd_change[7:4];
                digit0 = bcd_change[3:0];
            end
            default: begin
                digit3 = 4'hF;
                digit2 = 4'hF;
                digit1 = 4'hF;
                digit0 = 4'hF;
            end
        endcase
    end

endmodule
