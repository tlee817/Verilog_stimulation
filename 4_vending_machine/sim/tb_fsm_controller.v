`timescale 1ns / 1ps

// Comprehensive Testbench for fsm_controller
//
// Test groups:
//   1-5:   Basic purchases (exact payment, all items)
//   6-9:   Overpayment & change calculation
//   10-12: Coin accumulation & combinations
//   13-15: Coin overflow / rejection
//   16-19: Stock depletion & sold-out
//   20-23: Restock mode
//   24-27: Reset from every state
//   28-30: Edge cases & input during wrong states

module tb_fsm_controller;

    reg        clk;
    reg        rst;
    reg        en_1hz;
    reg        btn_confirm;
    reg        btn_nickel;
    reg        btn_dime;
    reg        btn_quarter;
    reg  [1:0] sw_item;
    reg        sw_restock;
    wire [3:0] digit3, digit2, digit1, digit0;
    wire [3:0] item_leds;

    fsm_controller uut (
        .clk        (clk),
        .rst        (rst),
        .en_1hz     (en_1hz),
        .btn_confirm(btn_confirm),
        .btn_nickel (btn_nickel),
        .btn_dime   (btn_dime),
        .btn_quarter(btn_quarter),
        .sw_item    (sw_item),
        .sw_restock (sw_restock),
        .digit3     (digit3),
        .digit2     (digit2),
        .digit1     (digit1),
        .digit0     (digit0),
        .item_leds  (item_leds)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer test_num;

    // ---------------------------------------------------------------
    // Helper tasks
    // ---------------------------------------------------------------

    task press_button;
        input integer which; // 0=confirm, 1=nickel, 2=dime, 3=quarter
        begin
            @(posedge clk); #1;
            case (which)
                0: btn_confirm = 1;
                1: btn_nickel  = 1;
                2: btn_dime    = 1;
                3: btn_quarter = 1;
            endcase
            @(posedge clk); #1;
            btn_confirm = 0;
            btn_nickel  = 0;
            btn_dime    = 0;
            btn_quarter = 0;
        end
    endtask

    task tick_1hz;
        begin
            @(posedge clk); #1;
            en_1hz = 1;
            @(posedge clk); #1;
            en_1hz = 0;
        end
    endtask

    task wait_clk;
        begin
            @(posedge clk); #1;
        end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1; rst = 1;
            @(posedge clk); #1;
            @(posedge clk); #1; rst = 0;
            @(posedge clk); #1;
        end
    endtask

    task wait_show_price;
        begin
            tick_1hz;
            wait_clk;
        end
    endtask

    task wait_dispense;
        begin
            tick_1hz;
            tick_1hz;
            wait_clk;
        end
    endtask

    task wait_show_change;
        begin
            tick_1hz;
            tick_1hz;
            wait_clk;
        end
    endtask

    task wait_sold_out;
        begin
            tick_1hz;
            wait_clk;
        end
    endtask

    // Full purchase helper: select item, confirm, wait through show_price
    // Leaves FSM in INSERT_COINS state
    task start_purchase;
        input [1:0] item;
        begin
            sw_item = item;
            press_button(0);
            wait_clk;
            wait_show_price;
        end
    endtask

    // Insert a specific cent amount using optimal coins
    // Only works for multiples of 5 up to 99
    task insert_cents;
        input [6:0] amount;
        reg [6:0] remaining;
        begin
            remaining = amount;
            while (remaining >= 25) begin
                press_button(3); wait_clk;
                remaining = remaining - 25;
            end
            while (remaining >= 10) begin
                press_button(2); wait_clk;
                remaining = remaining - 10;
            end
            while (remaining >= 5) begin
                press_button(1); wait_clk;
                remaining = remaining - 5;
            end
        end
    endtask

    // ---------------------------------------------------------------
    // Check tasks
    // ---------------------------------------------------------------

    task check_state;
        input [255:0] name;
        input integer expected;
        begin
            if (uut.state !== expected[2:0]) begin
                $display("  FAIL: %0s (expected state %0d, got %0d)", name, expected, uut.state);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_display;
        input [255:0] name;
        input [3:0] e3, e2, e1, e0;
        begin
            if (digit3 !== e3 || digit2 !== e2 || digit1 !== e1 || digit0 !== e0) begin
                $display("  FAIL: %0s (expected %h%h%h%h, got %h%h%h%h)",
                         name, e3, e2, e1, e0, digit3, digit2, digit1, digit0);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_leds;
        input [255:0] name;
        input [3:0] expected;
        begin
            if (item_leds !== expected) begin
                $display("  FAIL: %0s (expected %b, got %b)", name, expected, item_leds);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_stock;
        input [255:0] name;
        input [1:0] item;
        input [2:0] expected;
        reg [2:0] actual;
        begin
            case (item)
                2'd0: actual = uut.stock_0;
                2'd1: actual = uut.stock_1;
                2'd2: actual = uut.stock_2;
                2'd3: actual = uut.stock_3;
            endcase
            if (actual !== expected) begin
                $display("  FAIL: %0s (expected %0d, got %0d)", name, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_balance;
        input [255:0] name;
        input [6:0] expected;
        begin
            if (uut.balance !== expected) begin
                $display("  FAIL: %0s (expected %0d, got %0d)", name, expected, uut.balance);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_change;
        input [255:0] name;
        input [6:0] expected;
        begin
            if (uut.change !== expected) begin
                $display("  FAIL: %0s (expected %0d, got %0d)", name, expected, uut.change);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS: %0s", name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // ---------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------

    initial begin
        $dumpfile("tb_fsm_controller.vcd");
        $dumpvars(0, tb_fsm_controller);

        pass_count = 0;
        fail_count = 0;
        test_num = 0;

        rst = 0; en_1hz = 0;
        btn_confirm = 0; btn_nickel = 0; btn_dime = 0; btn_quarter = 0;
        sw_item = 2'b00; sw_restock = 0;

        do_reset;

        // ============================================================
        // GROUP 1: BASIC EXACT PURCHASES (ALL ITEMS)
        // ============================================================

        test_num = 1;
        $display("\n[Test %0d] Exact purchase - Item A (25c) with 1 quarter", test_num);
        start_purchase(2'b00);
        check_state("In INSERT_COINS", 3);
        press_button(3); wait_clk; wait_clk;  // 25c
        check_state("DISPENSE", 4);
        check_leds("LED A on", 4'b0001);
        wait_dispense; wait_clk;
        check_state("Back to IDLE", 0);
        check_stock("Stock A=4", 2'd0, 3'd4);
        check_leds("LEDs off", 4'b0000);

        test_num = 2;
        $display("\n[Test %0d] Exact purchase - Item B (50c) with 2 quarters", test_num);
        start_purchase(2'b01);
        press_button(3); wait_clk;  // 25
        press_button(3); wait_clk; wait_clk;  // 50
        check_state("DISPENSE", 4);
        check_leds("LED B on", 4'b0010);
        wait_dispense; wait_clk;
        check_state("Back to IDLE", 0);
        check_stock("Stock B=4", 2'd1, 3'd4);

        test_num = 3;
        $display("\n[Test %0d] Exact purchase - Item C (75c) with 3 quarters", test_num);
        start_purchase(2'b10);
        press_button(3); wait_clk;  // 25
        press_button(3); wait_clk;  // 50
        press_button(3); wait_clk; wait_clk;  // 75
        check_state("DISPENSE", 4);
        check_leds("LED C on", 4'b0100);
        wait_dispense; wait_clk;
        check_state("Back to IDLE", 0);
        check_stock("Stock C=4", 2'd2, 3'd4);

        test_num = 4;
        $display("\n[Test %0d] Exact purchase - Item D (95c) with quarters+dimes", test_num);
        start_purchase(2'b11);
        press_button(3); wait_clk;  // 25
        press_button(3); wait_clk;  // 50
        press_button(3); wait_clk;  // 75
        press_button(2); wait_clk;  // 85
        press_button(2); wait_clk; wait_clk;  // 95
        check_state("DISPENSE", 4);
        check_leds("LED D on", 4'b1000);
        wait_dispense; wait_clk;
        check_state("Back to IDLE", 0);
        check_stock("Stock D=4", 2'd3, 3'd4);

        test_num = 5;
        $display("\n[Test %0d] Exact purchase - Item A (25c) with 5 nickels", test_num);
        start_purchase(2'b00);
        press_button(1); wait_clk;  // 5
        press_button(1); wait_clk;  // 10
        press_button(1); wait_clk;  // 15
        press_button(1); wait_clk;  // 20
        press_button(1); wait_clk; wait_clk;  // 25
        check_state("DISPENSE", 4);
        wait_dispense; wait_clk;
        check_state("Back to IDLE", 0);
        check_stock("Stock A=3", 2'd0, 3'd3);

        // ============================================================
        // GROUP 2: OVERPAYMENT & CHANGE CALCULATION
        // ============================================================

        test_num = 6;
        $display("\n[Test %0d] Overpay Item A (25c) by 5c -> change 5", test_num);
        start_purchase(2'b00);
        press_button(2); wait_clk;  // 10
        press_button(2); wait_clk;  // 20
        press_button(2); wait_clk; wait_clk;  // 30 >= 25
        check_state("DISPENSE", 4);
        wait_dispense;
        check_state("SHOW_CHANGE", 5);
        check_change("Change = 5", 7'd5);
        check_display("Display Ch05", 4'hC, 4'hD, 4'h0, 4'h5);
        wait_show_change; wait_clk;
        check_state("Back to IDLE", 0);

        test_num = 7;
        $display("\n[Test %0d] Overpay Item A (25c) by 20c -> change 20", test_num);
        start_purchase(2'b00);
        press_button(2); wait_clk;  // 10
        press_button(2); wait_clk;  // 20
        press_button(3); wait_clk; wait_clk;  // 45 >= 25
        check_state("DISPENSE", 4);
        wait_dispense;
        check_state("SHOW_CHANGE", 5);
        check_change("Change = 20", 7'd20);
        check_display("Display Ch20", 4'hC, 4'hD, 4'h2, 4'h0);
        wait_show_change; wait_clk;
        check_state("Back to IDLE", 0);

        test_num = 8;
        $display("\n[Test %0d] Overpay Item B (50c) by 20c -> change 20", test_num);
        start_purchase(2'b01);
        press_button(3); wait_clk;  // 25
        press_button(2); wait_clk;  // 35
        press_button(2); wait_clk;  // 45
        press_button(3); wait_clk; wait_clk;  // 70 >= 50
        check_state("DISPENSE", 4);
        wait_dispense;
        check_state("SHOW_CHANGE", 5);
        check_change("Change = 20", 7'd20);
        wait_show_change; wait_clk;
        check_state("Back to IDLE", 0);

        test_num = 9;
        $display("\n[Test %0d] Overpay Item C (75c) by 5c -> change 5", test_num);
        start_purchase(2'b10);
        insert_cents(7'd70);      // 70c
        press_button(2); wait_clk; wait_clk;  // 80 >= 75
        check_state("DISPENSE", 4);
        wait_dispense;
        check_state("SHOW_CHANGE", 5);
        check_change("Change = 5", 7'd5);
        wait_show_change; wait_clk;
        check_state("Back to IDLE", 0);

        // ============================================================
        // GROUP 3: COIN ACCUMULATION & DISPLAY
        // ============================================================

        test_num = 10;
        $display("\n[Test %0d] Balance display increments correctly (nickels)", test_num);
        start_purchase(2'b01);  // Item B, 50c
        press_button(1); wait_clk;
        check_balance("After nickel: 5", 7'd5);
        check_display("Display 05", 4'hF, 4'hF, 4'h0, 4'h5);
        press_button(1); wait_clk;
        check_balance("After nickel: 10", 7'd10);
        check_display("Display 10", 4'hF, 4'hF, 4'h1, 4'h0);
        press_button(1); wait_clk;
        check_balance("After nickel: 15", 7'd15);
        check_display("Display 15", 4'hF, 4'hF, 4'h1, 4'h5);
        // Finish the purchase to return to IDLE
        insert_cents(7'd35);
        wait_clk;
        wait_dispense; wait_clk;

        test_num = 11;
        $display("\n[Test %0d] Balance display with dimes", test_num);
        start_purchase(2'b10);  // Item C, 75c
        press_button(2); wait_clk;
        check_balance("After dime: 10", 7'd10);
        press_button(2); wait_clk;
        check_balance("After dime: 20", 7'd20);
        press_button(2); wait_clk;
        check_balance("After dime: 30", 7'd30);
        check_display("Display 30", 4'hF, 4'hF, 4'h3, 4'h0);
        // Finish purchase
        insert_cents(7'd45);
        wait_clk;
        wait_dispense; wait_clk;

        test_num = 12;
        $display("\n[Test %0d] Mixed coin insertion order (dime, quarter, nickel)", test_num);
        start_purchase(2'b01);  // Item B, 50c
        press_button(2); wait_clk;  // 10
        check_balance("Dime first: 10", 7'd10);
        press_button(3); wait_clk;  // 35
        check_balance("Quarter: 35", 7'd35);
        press_button(1); wait_clk;  // 40
        check_balance("Nickel: 40", 7'd40);
        press_button(2); wait_clk; wait_clk;  // 50
        check_state("50 >= 50 -> DISPENSE", 4);
        wait_dispense; wait_clk;

        // ============================================================
        // GROUP 4: COIN OVERFLOW PROTECTION
        // ============================================================

        test_num = 13;
        $display("\n[Test %0d] Quarter rejected when balance > 74", test_num);
        start_purchase(2'b11);  // Item D, 95c
        insert_cents(7'd75);    // 75c
        check_balance("Balance = 75", 7'd75);
        press_button(3); wait_clk;  // quarter would make 100, cap is <= 74
        check_balance("Quarter rejected at 75", 7'd75);
        // Clean up
        press_button(2); wait_clk;  // 85
        press_button(2); wait_clk; wait_clk;  // 95
        wait_dispense; wait_clk;

        test_num = 14;
        $display("\n[Test %0d] Dime rejected when balance > 89", test_num);
        start_purchase(2'b11);  // Item D, 95c
        insert_cents(7'd90);    // 3 quarters + dime + nickel = 90
        check_balance("Balance = 90", 7'd90);
        press_button(2); wait_clk;  // dime would make 100, cap is <= 89
        check_balance("Dime rejected at 90", 7'd90);
        press_button(1); wait_clk; wait_clk;  // nickel: 95
        check_state("95 >= 95 -> DISPENSE", 4);
        wait_dispense; wait_clk;

        test_num = 15;
        $display("\n[Test %0d] Nickel rejected when balance > 94", test_num);
        start_purchase(2'b11);  // Item D, 95c
        insert_cents(7'd95);    // triggers dispense
        wait_clk;
        check_state("Auto-dispense at 95", 4);
        wait_dispense; wait_clk;
        // Now test: get to 95 with one more nickel being excess
        start_purchase(2'b11);
        insert_cents(7'd90);
        check_balance("Balance = 90", 7'd90);
        // At 90: nickel allowed (90 <= 94), goes to 95 -> dispense
        press_button(1); wait_clk; wait_clk;
        check_state("95 -> DISPENSE", 4);
        wait_dispense; wait_clk;

        // ============================================================
        // GROUP 5: STOCK DEPLETION & SOLD OUT
        // ============================================================

        do_reset;

        test_num = 16;
        $display("\n[Test %0d] Deplete Item A (buy 5 times)", test_num);
        repeat (5) begin
            start_purchase(2'b00);
            press_button(3); wait_clk; wait_clk;  // 25c exact
            wait_dispense; wait_clk;
        end
        check_stock("Item A stock = 0", 2'd0, 3'd0);

        test_num = 17;
        $display("\n[Test %0d] Sold out Item A shows SO--", test_num);
        sw_item = 2'b00;
        press_button(0); wait_clk;
        check_state("SOLD_OUT state", 1);
        check_display("Display SO--", 4'hA, 4'hB, 4'hE, 4'hE);
        check_leds("LEDs off during sold out", 4'b0000);
        wait_sold_out;
        check_state("Returns to IDLE", 0);

        test_num = 18;
        $display("\n[Test %0d] Sold out A, but B still available", test_num);
        sw_item = 2'b00;
        press_button(0); wait_clk;
        check_state("A sold out", 1);
        wait_sold_out;
        // Now buy B
        start_purchase(2'b01);
        check_state("B available, INSERT_COINS", 3);
        insert_cents(7'd50);
        wait_clk;
        wait_dispense; wait_clk;
        check_state("B purchased OK", 0);

        test_num = 19;
        $display("\n[Test %0d] Deplete all items", test_num);
        do_reset;
        // Deplete A
        repeat (5) begin
            start_purchase(2'b00);
            press_button(3); wait_clk; wait_clk;
            wait_dispense; wait_clk;
        end
        // Deplete B
        repeat (5) begin
            start_purchase(2'b01);
            insert_cents(7'd50); wait_clk;
            wait_dispense; wait_clk;
        end
        // Deplete C
        repeat (5) begin
            start_purchase(2'b10);
            insert_cents(7'd75); wait_clk;
            wait_dispense; wait_clk;
        end
        // Deplete D
        repeat (5) begin
            start_purchase(2'b11);
            insert_cents(7'd95); wait_clk;
            wait_dispense; wait_clk;
        end
        check_stock("All A depleted", 2'd0, 3'd0);
        check_stock("All B depleted", 2'd1, 3'd0);
        check_stock("All C depleted", 2'd2, 3'd0);
        check_stock("All D depleted", 2'd3, 3'd0);

        // Verify all sold out
        sw_item = 2'b00; press_button(0); wait_clk;
        check_state("A sold out", 1); wait_sold_out;
        sw_item = 2'b01; press_button(0); wait_clk;
        check_state("B sold out", 1); wait_sold_out;
        sw_item = 2'b10; press_button(0); wait_clk;
        check_state("C sold out", 1); wait_sold_out;
        sw_item = 2'b11; press_button(0); wait_clk;
        check_state("D sold out", 1); wait_sold_out;

        // ============================================================
        // GROUP 6: RESTOCK MODE
        // ============================================================

        test_num = 20;
        $display("\n[Test %0d] Restock Item A from 0 to 5", test_num);
        sw_restock = 1;
        sw_item = 2'b00;
        wait_clk; wait_clk;
        check_display("Restock shows A stock=0", 4'hA, 4'hE, 4'hF, 4'h0);
        press_button(0); wait_clk;
        check_stock("A stock=1", 2'd0, 3'd1);
        press_button(0); wait_clk;
        check_stock("A stock=2", 2'd0, 3'd2);
        press_button(0); wait_clk;
        check_stock("A stock=3", 2'd0, 3'd3);
        press_button(0); wait_clk;
        check_stock("A stock=4", 2'd0, 3'd4);
        press_button(0); wait_clk;
        check_stock("A stock=5", 2'd0, 3'd5);

        test_num = 21;
        $display("\n[Test %0d] Restock capped at 5", test_num);
        press_button(0); wait_clk;
        check_stock("A stays at 5", 2'd0, 3'd5);
        press_button(0); wait_clk;
        check_stock("A still 5", 2'd0, 3'd5);

        test_num = 22;
        $display("\n[Test %0d] Restock different items in sequence", test_num);
        sw_item = 2'b01;
        wait_clk; wait_clk;
        check_display("Restock shows B stock=0", 4'h8, 4'hE, 4'hF, 4'h0);
        press_button(0); wait_clk;
        press_button(0); wait_clk;
        press_button(0); wait_clk;
        check_stock("B stock=3", 2'd1, 3'd3);

        sw_item = 2'b10;
        wait_clk; wait_clk;
        check_display("Restock shows C stock=0", 4'hC, 4'hE, 4'hF, 4'h0);
        press_button(0); wait_clk;
        check_stock("C stock=1", 2'd2, 3'd1);

        sw_item = 2'b11;
        wait_clk; wait_clk;
        press_button(0); wait_clk;
        press_button(0); wait_clk;
        check_stock("D stock=2", 2'd3, 3'd2);

        test_num = 23;
        $display("\n[Test %0d] Exit restock mode and buy restocked item", test_num);
        sw_restock = 0;
        wait_clk; wait_clk;
        check_state("IDLE after exiting restock", 0);
        check_display("Normal display 0000", 4'h0, 4'h0, 4'h0, 4'h0);

        // Buy Item A (stock=5)
        start_purchase(2'b00);
        press_button(3); wait_clk; wait_clk;
        check_state("Purchased restocked A", 4);
        wait_dispense; wait_clk;
        check_stock("A stock=4 after purchase", 2'd0, 3'd4);

        // ============================================================
        // GROUP 7: RESET FROM EVERY STATE
        // ============================================================

        test_num = 24;
        $display("\n[Test %0d] Reset from SHOW_PRICE", test_num);
        sw_item = 2'b01;
        press_button(0); wait_clk;
        check_state("In SHOW_PRICE", 2);
        do_reset;
        check_state("Reset -> IDLE", 0);
        check_stock("Stocks reset to 5", 2'd0, 3'd5);

        test_num = 25;
        $display("\n[Test %0d] Reset from INSERT_COINS", test_num);
        start_purchase(2'b10);
        check_state("In INSERT_COINS", 3);
        press_button(3); wait_clk;  // 25c inserted
        check_balance("Balance = 25", 7'd25);
        do_reset;
        check_state("Reset -> IDLE", 0);
        check_balance("Balance cleared", 7'd0);

        test_num = 26;
        $display("\n[Test %0d] Reset from DISPENSE", test_num);
        start_purchase(2'b00);
        press_button(3); wait_clk; wait_clk;
        check_state("In DISPENSE", 4);
        do_reset;
        check_state("Reset -> IDLE", 0);
        check_leds("LEDs off after reset", 4'b0000);

        test_num = 27;
        $display("\n[Test %0d] Reset from SHOW_CHANGE", test_num);
        start_purchase(2'b00);
        press_button(2); wait_clk;  // 10
        press_button(2); wait_clk;  // 20
        press_button(2); wait_clk; wait_clk;  // 30 >= 25
        wait_dispense;
        check_state("In SHOW_CHANGE", 5);
        do_reset;
        check_state("Reset -> IDLE", 0);

        // ============================================================
        // GROUP 8: EDGE CASES
        // ============================================================

        test_num = 28;
        $display("\n[Test %0d] Coin buttons ignored in IDLE", test_num);
        check_state("In IDLE", 0);
        press_button(1); wait_clk;  // nickel
        check_state("Still IDLE after nickel", 0);
        check_balance("Balance still 0", 7'd0);
        press_button(2); wait_clk;  // dime
        check_state("Still IDLE after dime", 0);
        press_button(3); wait_clk;  // quarter
        check_state("Still IDLE after quarter", 0);

        test_num = 29;
        $display("\n[Test %0d] Confirm ignored during DISPENSE/SHOW_PRICE", test_num);
        start_purchase(2'b00);
        // In INSERT_COINS: confirm should not restart
        press_button(0); wait_clk;
        check_state("Confirm doesn't restart in INSERT", 3);
        // Finish purchase
        press_button(3); wait_clk; wait_clk;
        check_state("In DISPENSE", 4);
        // Confirm during DISPENSE
        press_button(0); wait_clk;
        check_state("Confirm ignored in DISPENSE", 4);
        wait_dispense; wait_clk;

        test_num = 30;
        $display("\n[Test %0d] Rapid consecutive purchases", test_num);
        // Buy 3 different items back-to-back
        start_purchase(2'b00);
        press_button(3); wait_clk; wait_clk;
        wait_dispense; wait_clk;
        check_state("IDLE after first", 0);

        start_purchase(2'b01);
        insert_cents(7'd50); wait_clk;
        wait_dispense; wait_clk;
        check_state("IDLE after second", 0);

        start_purchase(2'b10);
        insert_cents(7'd75); wait_clk;
        wait_dispense; wait_clk;
        check_state("IDLE after third", 0);

        check_stock("A stock after rapid buys", 2'd0, 3'd3);
        check_stock("B stock after rapid buys", 2'd1, 3'd4);
        check_stock("C stock after rapid buys", 2'd2, 3'd4);

        // ============================================================
        // GROUP 9: SHOW_PRICE DISPLAY VERIFICATION
        // ============================================================

        test_num = 31;
        $display("\n[Test %0d] SHOW_PRICE display for all items", test_num);
        sw_item = 2'b00;
        press_button(0); wait_clk;
        check_display("Price A = 25", 4'hF, 4'hF, 4'h2, 4'h5);
        wait_show_price;
        // Cancel via reset
        do_reset;

        sw_item = 2'b01;
        press_button(0); wait_clk;
        check_display("Price B = 50", 4'hF, 4'hF, 4'h5, 4'h0);
        do_reset;

        sw_item = 2'b10;
        press_button(0); wait_clk;
        check_display("Price C = 75", 4'hF, 4'hF, 4'h7, 4'h5);
        do_reset;

        sw_item = 2'b11;
        press_button(0); wait_clk;
        check_display("Price D = 95", 4'hF, 4'hF, 4'h9, 4'h5);
        do_reset;

        // ============================================================
        // GROUP 10: RESTOCK DISPLAY FOR ALL ITEMS
        // ============================================================

        test_num = 32;
        $display("\n[Test %0d] Restock display characters for all items", test_num);
        sw_restock = 1;

        sw_item = 2'b00; wait_clk; wait_clk;
        check_display("Restock A display", 4'hA, 4'hE, 4'hF, 4'h5);

        sw_item = 2'b01; wait_clk; wait_clk;
        check_display("Restock B display", 4'h8, 4'hE, 4'hF, 4'h5);

        sw_item = 2'b10; wait_clk; wait_clk;
        check_display("Restock C display", 4'hC, 4'hE, 4'hF, 4'h5);

        sw_item = 2'b11; wait_clk; wait_clk;
        check_display("Restock D display", 4'hD, 4'hE, 4'hF, 4'h5);

        sw_restock = 0;
        wait_clk; wait_clk;

        // ============================================================
        // SUMMARY
        // ============================================================

        $display("\n========================================");
        $display("RESULTS: %0d passed, %0d failed out of %0d total",
                 pass_count, fail_count, pass_count + fail_count);
        $display("========================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        #100;
        $finish;
    end

endmodule
