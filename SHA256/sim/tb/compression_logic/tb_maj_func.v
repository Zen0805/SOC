//-----------------------------------------------------------------------------
// Testbench cho maj_func
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_maj_func();

    reg  [31:0] test_x, test_y, test_z;
    wire [31:0] w_maj_out;

    // --- Giá trị mong đợi ---
    localparam X_A = 32'hAAAAAAAA; // Input ví dụ
    localparam Y_B = 32'h55555555; // Input ví dụ
    localparam Z_C = 32'hF0F0F0F0; // Input ví dụ
    localparam EXP_MAJ_000 = 32'h00000000; // Maj(0,0,0) = 0
    localparam EXP_MAJ_FFF = 32'hFFFFFFFF; // Maj(F,F,F) = F^F^F = F
    localparam EXP_MAJ_ABC = 32'hF0F0F0F0; // Maj(A,B,C) = (A&B)^(A&C)^(B&C) = 0 ^ (A&C) ^ (B&C) = 0xA0A0A0A0 ^ 0x50505050 = 0xF0F0F0F0

    maj_func uut ( .x(test_x), .y(test_y), .z(test_z), .out(w_maj_out) );

    initial begin
        test_x = 32'b0; test_y = 32'b0; test_z = 32'b0;
        $display("--- Bắt đầu test maj_func ---");

        // Test Case 1: x=0, y=0, z=0
        #10; test_x = 32'h0; test_y = 32'h0; test_z = 32'h0; #1;
        $display("Test Case 1: x=%h, y=%h, z=%h", test_x, test_y, test_z);
        $display("  Maj: Out=%h, Exp=%h --> %s", w_maj_out, EXP_MAJ_000, (w_maj_out === EXP_MAJ_000) ? "PASS" : "FAIL");

        // Test Case 2: x=F, y=F, z=F
        #10; test_x = 32'hFFFFFFFF; test_y = 32'hFFFFFFFF; test_z = 32'hFFFFFFFF; #1;
        $display("Test Case 2: x=%h, y=%h, z=%h", test_x, test_y, test_z);
        $display("  Maj: Out=%h, Exp=%h --> %s", w_maj_out, EXP_MAJ_FFF, (w_maj_out === EXP_MAJ_FFF) ? "PASS" : "FAIL");

        // Test Case 3: x=A, y=B, z=C
        #10; test_x = X_A; test_y = Y_B; test_z = Z_C; #1;
        $display("Test Case 3: x=%h, y=%h, z=%h", test_x, test_y, test_z);
        $display("  Maj: Out=%h, Exp=%h --> %s", w_maj_out, EXP_MAJ_ABC, (w_maj_out === EXP_MAJ_ABC) ? "PASS" : "FAIL");

        #20;
        $display("--- Kết thúc test maj_func ---");
        $finish;
    end
endmodule