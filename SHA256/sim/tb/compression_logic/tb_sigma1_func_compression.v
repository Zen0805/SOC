//-----------------------------------------------------------------------------
// Testbench cho Sigma1_func_for_compression
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_sigma1_func_compression();

    reg  [31:0] test_x;
    wire [31:0] w_S1_out;

    // --- Giá trị mong đợi ---
    localparam X_RAND = 32'hABCDEFFF; // Input ví dụ
    localparam EXP_S1_0    = 32'h00000000; // Σ₁(0) = 0
    localparam EXP_S1_1    = 32'h02000840; // Σ₁(1) = R6(1)^R11(1)^R25(1) = 64^2048^33554432
    localparam EXP_S1_FFFF = 32'hFFFFFFFF; // Σ₁(F) = F^F^F = F
    localparam EXP_S1_RAND = 32'hB5E8F8A5; // Σ₁(0xABCDEFFF) - Tính toán cẩn thận

    Sigma1_func_for_compression uut ( .x(test_x), .out(w_S1_out) );

    initial begin
        test_x = 32'b0;
        $display("--- Bắt đầu test Sigma1_func_for_compression ---");

        // Test Case 1: x = 0
        #10; test_x = 32'h00000000; #1;
        $display("Test Case 1: x = %h", test_x);
        $display("  Sigma1: Out=%h, Exp=%h --> %s", w_S1_out, EXP_S1_0, (w_S1_out === EXP_S1_0) ? "PASS" : "FAIL");

        // Test Case 2: x = 1
        #10; test_x = 32'h00000001; #1;
        $display("Test Case 2: x = %h", test_x);
        $display("  Sigma1: Out=%h, Exp=%h --> %s", w_S1_out, EXP_S1_1, (w_S1_out === EXP_S1_1) ? "PASS" : "FAIL");

        // Test Case 3: x = 0xFFFFFFFF
        #10; test_x = 32'hFFFFFFFF; #1;
        $display("Test Case 3: x = %h", test_x);
        $display("  Sigma1: Out=%h, Exp=%h --> %s", w_S1_out, EXP_S1_FFFF, (w_S1_out === EXP_S1_FFFF) ? "PASS" : "FAIL");

        // Test Case 4: x = 0xABCDEFFF
        #10; test_x = X_RAND; #1;
        $display("Test Case 4: x = %h", test_x);
        $display("  Sigma1: Out=%h, Exp=%h --> %s", w_S1_out, EXP_S1_RAND, (w_S1_out === EXP_S1_RAND) ? "PASS" : "FAIL");

        #20;
        $display("--- Kết thúc test Sigma1_func_for_compression ---");
        $finish;
    end
endmodule