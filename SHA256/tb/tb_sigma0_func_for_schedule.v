//-----------------------------------------------------------------------------
// Module: tb_sigma0_func
// Tác giả: Tao
// Chức năng: Testbench riêng cho module sigma0_func.
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_sigma0_func_for_schedule();

    // --- Tín hiệu điều khiển testbench ---
    reg  [31:0] test_x; // Đầu vào x để test

    // --- Tín hiệu nối với DUT ---
    wire [31:0] w_sigma0_out; // Output sigma0 từ DUT

    // --- Định nghĩa giá trị mong đợi (Expected Values) ---
    localparam EXP_S0_0    = 32'h00000000; // sigma0(0) = 0
    localparam EXP_S0_1    = 32'h02004000; // sigma0(1) = ROTR7(1)^ROTR18(1)^SHR3(1)
    localparam EXP_S0_FFFF = 32'h1FFFFFFF; // sigma0(0xFFFFFFFF)
    localparam EXP_S0_RAND = 32'h91d1ccd3; // sigma0(0xABCDEFFF) - Đã kiểm tra bằng Python

    // --- Instantiate DUT ---
    sigma0_func_for_schedule uut (
        .x(test_x),
        .out(w_sigma0_out)
    );

    // --- Luồng test chính ---
    initial begin
        // Khởi tạo
        test_x = 32'b0;
        $display("--- Bắt đầu test sigma0_func ---");

        // Test Case 1: x = 0
        #10;
        test_x = 32'h00000000;
        #1;
        $display("Test Case 1: x = %h", test_x);
        $display("  sigma0: Out=%h, Exp=%h --> %s", w_sigma0_out, EXP_S0_0, (w_sigma0_out === EXP_S0_0) ? "PASS" : "FAIL");

        // Test Case 2: x = 1
        #10;
        test_x = 32'h00000001;
        #1;
        $display("Test Case 2: x = %h", test_x);
        $display("  sigma0: Out=%h, Exp=%h --> %s", w_sigma0_out, EXP_S0_1, (w_sigma0_out === EXP_S0_1) ? "PASS" : "FAIL");

        // Test Case 3: x = 0xFFFFFFFF
        #10;
        test_x = 32'hFFFFFFFF;
        #1;
        $display("Test Case 3: x = %h", test_x);
        $display("  sigma0: Out=%h, Exp=%h --> %s", w_sigma0_out, EXP_S0_FFFF, (w_sigma0_out === EXP_S0_FFFF) ? "PASS" : "FAIL");

        // Test Case 4: x = 0xABCDEFFF
        #10;
        test_x = 32'hABCDEFFF;
        #1;
        $display("Test Case 4: x = %h", test_x);
        $display("  sigma0: Out=%h, Exp=%h --> %s", w_sigma0_out, EXP_S0_RAND, (w_sigma0_out === EXP_S0_RAND) ? "PASS" : "FAIL");

        #20;
        $display("--- Kết thúc test sigma0_func ---");
        $finish;
    end

    // (Optional) Dump waveform
    // initial begin
    //     $dumpfile("tb_sigma0_func.vcd");
    //     $dumpvars(0, tb_sigma0_func);
    // end

endmodule