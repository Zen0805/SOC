//-----------------------------------------------------------------------------
// Testbench cho Sigma0_func_for_compression
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_sigma0_func_compression();

    reg  [31:0] test_x;
    wire [31:0] w_S0_out;

    // --- Giá trị mong đợi ---
    localparam X_RAND = 32'hABCDEFFF; // Input ví dụ
    localparam EXP_S0_0    = 32'h00000000; // Σ₀(0) = 0
    localparam EXP_S0_1    = 32'h00502004; // Σ₀(1) = R2(1)^R13(1)^R22(1) = 4^8192^524288
    localparam EXP_S0_FFFF = 32'hFFFFFFFF; // Σ₀(F) = F^F^F = F
    localparam EXP_S0_RAND = 32'h06E8697A; // Σ₀(0xABCDEFFF) - Tính toán cẩn thận

    Sigma0_func_for_compression uut ( .x(test_x), .out(w_S0_out) );

    initial begin
        test_x = 32'b0;
        $display("--- Bắt đầu test Sigma0_func_for_compression ---");

        // Test Case 1: x = 0
        #10; test_x = 32'h00000000; #1;
        $display("Test Case 1: x = %h", test_x);
        $display("  Sigma0: Out=%h, Exp=%h --> %s", w_S0_out, EXP_S0_0, (w_S0_out === EXP_S0_0) ? "PASS" : "FAIL");

        // Test Case 2: x = 1
        #10; test_x = 32'h00000001; #1;
        $display("Test Case 2: x = %h", test_x);
        $display("  Sigma0: Out=%h, Exp=%h --> %s", w_S0_out, EXP_S0_1, (w_S0_out === EXP_S0_1) ? "PASS" : "FAIL");

        // Test Case 3: x = 0xFFFFFFFF
        #10; test_x = 32'hFFFFFFFF; #1;
        $display("Test Case 3: x = %h", test_x);
        $display("  Sigma0: Out=%h, Exp=%h --> %s", w_S0_out, EXP_S0_FFFF, (w_S0_out === EXP_S0_FFFF) ? "PASS" : "FAIL");

        // Test Case 4: x = 0xABCDEFFF
        #10; test_x = X_RAND; #1;
        $display("Test Case 4: x = %h", test_x);
        $display("  Sigma0: Out=%h, Exp=%h --> %s", w_S0_out, EXP_S0_RAND, (w_S0_out === EXP_S0_RAND) ? "PASS" : "FAIL");

        #20;
        $display("--- Kết thúc test Sigma0_func_for_compression ---");
        $finish;
    end
endmodule