`timescale 1ns / 1ps

module FPCVT_tb();

    // Inputs to the Unit Under Test (UUT)
    reg [11:0] D;

    // Outputs from the UUT
    wire S;
    wire [2:0] E;
    wire [3:0] F;

    // Test statistics
    integer test_count;
    integer pass_count;
    integer fail_count;

    // Instantiate the Unit Under Test (UUT)
    FPCVT uut (
        .D(D),
        .S(S),
        .E(E),
        .F(F)
    );

    // Task to display test results
    task display_result;
        input [11:0] input_val;
        input [79:0] test_name;  // String for test description
        begin
            test_count = test_count + 1;
            $display("Test %0d: %s", test_count, test_name);
            $display("  Input D = 0x%h (%0d decimal, signed: %0d)",
                     input_val, input_val, $signed(input_val));
            $display("  Output: S=%b, E=%b (%0d), F=%b (%0d)",
                     S, E, E, F, F);
            // Calculate actual floating point value: (-1)^S * F * 2^E
            if (F != 0 || E != 0)
                $display("  FP Value = %s%0d * 2^%0d = %0d",
                         S ? "-" : "+", F, E, S ? -(F * (2**E)) : (F * (2**E)));
            else
                $display("  FP Value = 0");
            $display("");
        end
    endtask

    // Task to verify expected output
    task verify_output;
        input [11:0] input_val;
        input expected_s;
        input [2:0] expected_e;
        input [3:0] expected_f;
        input [79:0] test_name;
        begin
            test_count = test_count + 1;
            if (S === expected_s && E === expected_e && F === expected_f) begin
                pass_count = pass_count + 1;
                $display("PASS Test %0d: %s", test_count, test_name);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL Test %0d: %s", test_count, test_name);
                $display("  Input: 0x%h (%0d)", input_val, $signed(input_val));
                $display("  Expected: S=%b E=%b F=%b", expected_s, expected_e, expected_f);
                $display("  Got:      S=%b E=%b F=%b", S, E, F);
            end
        end
    endtask

    initial begin
        // Initialize
        D = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Wait for global reset
        #100;

        $display("========================================");
        $display("  FPCVT Comprehensive Test Suite");
        $display("  12-bit 2's Complement to 8-bit FP");
        $display("  Format: V = (-1)^S * F * 2^E");
        $display("========================================");
        $display("");

        //=============================================
        // Category 1: Zero and Special Cases
        //=============================================
        $display("=== Category 1: Zero and Special Cases ===");
        D = 12'h000; #10;
        display_result(D, "Zero value");

        //=============================================
        // Category 2: Positive Values - Small
        //=============================================
        $display("=== Category 2: Small Positive Values ===");

        D = 12'h001; #10;  // 1
        display_result(D, "Minimum positive (1)");

        D = 12'h002; #10;  // 2
        display_result(D, "Small positive (2)");

        D = 12'h003; #10;  // 3
        display_result(D, "Small positive (3)");

        D = 12'h007; #10;  // 7
        display_result(D, "Small positive (7)");

        D = 12'h008; #10;  // 8
        display_result(D, "Small positive (8)");

        D = 12'h00F; #10;  // 15
        display_result(D, "Small positive (15)");

        D = 12'h010; #10;  // 16 (power of 2)
        display_result(D, "Power of 2 (16)");

        //=============================================
        // Category 3: Positive Values - Medium
        //=============================================
        $display("=== Category 3: Medium Positive Values ===");

        D = 12'h020; #10;  // 32
        display_result(D, "Power of 2 (32)");

        D = 12'h040; #10;  // 64
        display_result(D, "Power of 2 (64)");

        D = 12'h05A; #10;  // 90
        display_result(D, "Medium positive (90)");

        D = 12'h080; #10;  // 128
        display_result(D, "Power of 2 (128)");

        D = 12'h0A5; #10;  // 165
        display_result(D, "Medium positive (165)");

        D = 12'h100; #10;  // 256
        display_result(D, "Power of 2 (256)");

        //=============================================
        // Category 4: Positive Values - Large
        //=============================================
        $display("=== Category 4: Large Positive Values ===");

        D = 12'h200; #10;  // 512
        display_result(D, "Power of 2 (512)");

        D = 12'h2AA; #10;  // 682
        display_result(D, "Large positive (682)");

        D = 12'h3FF; #10;  // 1023
        display_result(D, "Maximum positive (1023)");

        D = 12'h400; #10;  // 1024
        display_result(D, "Power of 2 (1024)");

        D = 12'h555; #10;  // 1365
        display_result(D, "Large positive (1365)");

        D = 12'h7FF; #10;  // 2047 (max positive 12-bit)
        display_result(D, "Maximum 12-bit positive (2047)");

        //=============================================
        // Category 5: Negative Values - Small
        //=============================================
        $display("=== Category 5: Small Negative Values ===");

        D = 12'hFFF; #10;  // -1
        display_result(D, "Negative (-1)");

        D = 12'hFFE; #10;  // -2
        display_result(D, "Negative (-2)");

        D = 12'hFFD; #10;  // -3
        display_result(D, "Negative (-3)");

        D = 12'hFF8; #10;  // -8
        display_result(D, "Negative (-8)");

        D = 12'hFF0; #10;  // -16
        display_result(D, "Negative power of 2 (-16)");

        //=============================================
        // Category 6: Negative Values - Medium
        //=============================================
        $display("=== Category 6: Medium Negative Values ===");

        D = 12'hFE0; #10;  // -32
        display_result(D, "Negative power of 2 (-32)");

        D = 12'hFC0; #10;  // -64
        display_result(D, "Negative power of 2 (-64)");

        D = 12'hF80; #10;  // -128
        display_result(D, "Negative power of 2 (-128)");

        D = 12'hF5B; #10;  // -165
        display_result(D, "Medium negative (-165)");

        D = 12'hF00; #10;  // -256
        display_result(D, "Negative power of 2 (-256)");

        //=============================================
        // Category 7: Negative Values - Large
        //=============================================
        $display("=== Category 7: Large Negative Values ===");

        D = 12'hE00; #10;  // -512
        display_result(D, "Negative power of 2 (-512)");

        D = 12'hD56; #10;  // -682
        display_result(D, "Large negative (-682)");

        D = 12'hC00; #10;  // -1024
        display_result(D, "Negative power of 2 (-1024)");

        D = 12'hAAB; #10;  // -1365
        display_result(D, "Large negative (-1365)");

        D = 12'h800; #10;  // -2048 (most negative)
        display_result(D, "Maximum negative (-2048)");

        //=============================================
        // Category 8: Rounding Test Cases
        //=============================================
        $display("=== Category 8: Rounding Test Cases ===");

        D = 12'h01F; #10;  // 31 (should test rounding)
        display_result(D, "Rounding case (31)");

        D = 12'h03F; #10;  // 63 (should test rounding)
        display_result(D, "Rounding case (63)");

        D = 12'h07F; #10;  // 127 (should test rounding)
        display_result(D, "Rounding case (127)");

        D = 12'h0FF; #10;  // 255 (should test rounding)
        display_result(D, "Rounding case (255)");

        D = 12'h1FF; #10;  // 511 (should test rounding)
        display_result(D, "Rounding case (511)");

        //=============================================
        // Category 9: Boundary Values
        //=============================================
        $display("=== Category 9: Boundary Values ===");

        D = 12'h7FE; #10;  // 2046
        display_result(D, "Near max positive (2046)");

        D = 12'h801; #10;  // -2047
        display_result(D, "Near max negative (-2047)");

        D = 12'h7FF; #10;  // 2047
        display_result(D, "Max positive boundary (2047)");

        D = 12'h800; #10;  // -2048
        display_result(D, "Max negative boundary (-2048)");

        //=============================================
        // Summary
        //=============================================
        #50;
        $display("========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0 && test_count > 0)
            $display("ALL TESTS PASSED!");
        $display("========================================");
        $display("");
        $display("Simulation Finished.");
        $finish;
    end

endmodule
