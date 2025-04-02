//-----------------------------------------------------------------------------
// Module: tb_sigma1_func
// Tác giả: Tao
// Chức năng: Testbench riêng cho module sigma1_func.
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_sigma1_func_for_schedule();

    // --- Tín hiệu điều khiển testbench ---
    reg  [31:0] test_x; // Đầu vào x để test

    // --- Tín hiệu nối với DUT ---
    wire [31:0] w_sigma1_out; // Output sigma1 từ DUT

    // --- Định nghĩa giá trị mong đợi (Expected Values) ---
    localparam EXP_S1_0    = 32'h00000000; // sigma1(0) = 0
    localparam EXP_S1_1    = 32'h0000A000; // sigma1(1) = ROTR17(1)^ROTR19(1)^SHR10(1)
    localparam EXP_S1_FFFF = 32'h003FFFFF; // sigma1(0xFFFFFFFF)
    localparam EXP_S1_RAND = 32'h02A038BD; // sigma1(0xABCDEFFF) - Đã kiểm tra bằng Python


    // --- Instantiate DUT ---
    sigma1_func uut (
        .x(test_x),
        .out(w_sigma1_out)
    );

    // --- Luồng test chính ---
    initial begin
        // Khởi tạo
        test_x = 32'b0;
        $display("--- Bắt đầu test sigma1_func ---");

        // Test Case 1: x = 0
        #10;
        test_x = 32'h00000000;
        #1;
        $display("Test Case 1: x = %h", test_x);
        $display("  sigma1: Out=%h, Exp=%h --> %s", w_sigma1_out, EXP_S1_0, (w_sigma1_out === EXP_S1_0) ? "PASS" : "FAIL");

        // Test Case 2: x = 1
        #10;
        test_x = 32'h00000001;
        #1;
        $display("Test Case 2: x = %h", test_x);
        $display("  sigma1: Out=%h, Exp=%h --> %s", w_sigma1_out, EXP_S1_1, (w_sigma1_out === EXP_S1_1) ? "PASS" : "FAIL");

        // Test Case 3: x = 0xFFFFFFFF
        #10;
        test_x = 32'hFFFFFFFF;
        #1;
        $display("Test Case 3: x = %h", test_x);
        $display("  sigma1: Out=%h, Exp=%h --> %s", w_sigma1_out, EXP_S1_FFFF, (w_sigma1_out === EXP_S1_FFFF) ? "PASS" : "FAIL");

        // Test Case 4: x = 0xABCDEFFF
        #10;
        test_x = 32'hABCDEFFF;
        #1;
        $display("Test Case 4: x = %h", test_x);
        $display("  sigma1: Out=%h, Exp=%h --> %s", w_sigma1_out, EXP_S1_RAND, (w_sigma1_out === EXP_S1_RAND) ? "PASS" : "FAIL");

        #20;
        $display("--- Kết thúc test sigma1_func ---");
        $finish;
    end

    // (Optional) Dump waveform
    // initial begin
    //     $dumpfile("tb_sigma1_func.vcd");
    //     $dumpvars(0, tb_sigma1_func);
    // end

endmodule