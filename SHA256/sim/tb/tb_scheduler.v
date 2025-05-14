//-----------------------------------------------------------------------------
// Testbench cho message_scheduler
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Testbench cho message_scheduler
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_message_scheduler();

    // --- Testbench Signals ---
    reg         clk;
    reg         reset_n;
    reg         start_new_block_tb;
    reg  [5:0]  round_t_tb;
    reg  [31:0] message_word_in_tb;
    reg  [3:0]  message_word_addr_tb;
    reg         write_enable_in_tb;
    reg         STN_tb;

    wire [31:0] Wt_out_dut;

    // --- Instantiate DUT ---
    message_scheduler uut (
        .clk(clk),
        .reset_n(reset_n),
        .start_new_block(start_new_block_tb),
        .STN(STN_tb),
        .round_t(round_t_tb),
        .message_word_in(message_word_in_tb),
        .message_word_addr(message_word_addr_tb),
        .write_enable_in(write_enable_in_tb),
        .Wt_out(Wt_out_dut)
    );

    // --- Clock Generation ---
    parameter CLK_PERIOD = 10; // Chu kỳ clock 10ns
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Test Sequence ---
    initial begin
        // 1. Reset
        reset_n = 1'b0;
        start_new_block_tb = 1'b0;
        STN_tb = 1'b1;
        round_t_tb = 6'b0;
        message_word_in_tb = 32'b0;
        message_word_addr_tb = 4'b0;
        write_enable_in_tb = 1'b0;
        $display("[%0t] Applying Reset...", $time);
        repeat (2) @(posedge clk);
        reset_n = 1'b1;
        $display("[%0t] Releasing Reset.", $time);
        @(posedge clk);

        // 2. Load Initial Message Block (M[0] to M[15])
        $display("[%0t] Loading initial message M[0..15]...", $time);
        start_new_block_tb = 1'b1;
        STN_tb = 1'b1; // Bật STN để bắt đầu ghi dữ liệu vào bộ nhớ
        write_enable_in_tb = 1'b1;
        for (integer i = 0; i < 16; i = i + 1) begin
            message_word_addr_tb = i[3:0];
            message_word_in_tb = i + 32'h10; // Ví dụ: M[i] = i + 0x10
            @(posedge clk);
        end
        write_enable_in_tb = 1'b0;
        start_new_block_tb = 1'b0;
        $display("[%0t] Finished loading message.", $time);
        @(posedge clk);

        // 3. Simulate Rounds (t=0 to t=63)
        $display("[%0t] Simulating SHA-256 rounds...", $time);
        for (integer t = 0; t < 64; t = t + 1) begin
            round_t_tb = t;
            if (t < 16) begin
                @(posedge clk);
                $display("[%0t] W[%0d] = 0x%h", $time, t, Wt_out_dut);
            end else begin
                repeat (5) @(posedge clk); // Chờ 5 chu kỳ để tính W[t]
                $display("[%0t] W[%0d] = 0x%h", $time, t, Wt_out_dut);
            end
        end
        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

endmodule