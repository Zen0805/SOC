//-----------------------------------------------------------------------------
// Module: message_scheduler
// Tác giả: Tao và mày hợp tác
// Chức năng: Tạo ra các message word W[t] cho thuật toán SHA-256.
//            Thực hiện theo kiến trúc tối ưu (Fig 5, Table 2 trong paper).
//            Sử dụng 1 adder, 1 reg_w, 1 memory 16x32-bit.
//            Tính W[t] (t>=16) trong 4 chu kỳ clock.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Module: adder_32bit
// Tác giả: Thằng bạn của mày
// Chức năng: Cộng hai cái số 32-bit lại với nhau.
//            Đơn giản như đang giỡn, nhưng mà quan trọng à nha.
//-----------------------------------------------------------------------------
module adder_32bit (
    // --- Đầu vào ---
    input wire [31:0] a,     // Số thứ nhất mày muốn cộng (32 bit)
    input wire [31:0] b,     // Số thứ hai mày muốn cộng (32 bit)

    // --- Đầu ra ---
    output wire [31:0] sum    // Kết quả tổng của a + b (32 bit)
);

    // --- Logic chính ---
    // Dùng 'assign' để gán giá trị cho đầu ra 'sum' một cách liên tục.
    // Nghĩa là bất cứ khi nào 'a' hoặc 'b' thay đổi, 'sum' nó tự cập nhật theo.
    // Cái này là mạch tổ hợp (combinational logic), không cần clock gì hết.
    // Toán tử '+' trong Verilog nó tự xử lý vụ cộng bit luôn, khỏe re.
    assign sum = a + b;

endmodule // Kết thúc module adder_32bit

//-----------------------------------------------------------------------------
// Module: sigma0_func_schedule
// Tác giả: ZenZ
// Chức năng: Tính hàm sigma0 (σ₀) của SHA-256.
//            σ₀(x) = ROTR⁷(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)
//-----------------------------------------------------------------------------
module sigma0_func_schedule (
    input wire [31:0] x,    // Đầu vào 32-bit
    output wire [31:0] out  // Kết quả sigma0(x) 32-bit
);

    // --- Tính toán trung gian ---
    wire [31:0] rotr7_x;  // Rotate Right 7 bits
    wire [31:0] rotr18_x; // Rotate Right 18 bits
    wire [31:0] shr3_x;   // Shift Right 3 bits (Logical)

    // --- Logic thực hiện các phép toán ---
    assign rotr7_x  = {x[6:0], x[31:7]};
    assign rotr18_x = {x[17:0], x[31:18]};
    assign shr3_x   = x >> 3;

    // Tính sigma0: ROTR7(x) ^ ROTR18(x) ^ SHR3(x)
    assign out = rotr7_x ^ rotr18_x ^ shr3_x;

endmodule


//-----------------------------------------------------------------------------
// Module: sigma1_func_schedule
// Tác giả: ZenZ
// Chức năng: Tính hàm sigma1 (σ₁) của SHA-256.
//            σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)
//-----------------------------------------------------------------------------
module sigma1_func_schedule (
    input wire [31:0] x,    // Đầu vào 32-bit
    output wire [31:0] out  // Kết quả sigma1(x) 32-bit
);

    // --- Tính toán trung gian ---
    wire [31:0] rotr17_x; // Rotate Right 17 bits
    wire [31:0] rotr19_x; // Rotate Right 19 bits
    wire [31:0] shr10_x;  // Shift Right 10 bits (Logical)

    // --- Logic thực hiện các phép toán ---
    assign rotr17_x = {x[16:0], x[31:17]};
    assign rotr19_x = {x[18:0], x[31:19]};
    assign shr10_x  = x >> 10;

    // Tính sigma1: ROTR17(x) ^ ROTR19(x) ^ SHR10(x)
    assign out = rotr17_x ^ rotr19_x ^ shr10_x;

endmodule

//-----------------------------------------------------------------------------
// Module: message_scheduler
// Tác giả: Được viết lại với sự hợp tác
// Chức năng: Tạo ra các message word W[t] cho thuật toán SHA-256.
//            Sử dụng kiến trúc tối ưu với 1 adder, 1 reg_w, và 1 memory 16x32-bit.
//            Tính W[t] (t >= 16) trong 4 chu kỳ clock.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Module: message_scheduler
// Tác giả: Được viết lại với sự hợp tác
// Chức năng: Tạo ra các message word W[t] cho thuật toán SHA-256.
//            Sử dụng kiến trúc tối ưu với 1 adder, 1 reg_w, và 1 memory 16x32-bit.
//            Tính W[t] (t >= 16) trong 4 chu kỳ clock.
//-----------------------------------------------------------------------------
module message_scheduler (
    // --- Interface ---
    input wire          clk,
    input wire          reset_n,         // Reset tích cực thấp
    input wire          start_new_block, // Báo hiệu bắt đầu block mới
    input wire [5:0]    round_t,         // Vòng lặp hiện tại (0-63)
    input wire [31:0]   message_word_in, // Dữ liệu M[i] để load
    input wire [3:0]    message_word_addr,// Địa chỉ (0-15) của M[i] đang load
    input wire          write_enable_in, // Cho phép ghi message_word_in vào memory
    output wire [31:0]  Wt_out           // W[t] tương ứng với round_t
);

    // --- Internal Signals ---
    reg [31:0] W_memory [15:0];     // Bộ nhớ lưu 16 từ W[t-16] đến W[t-1]
    reg [31:0] reg_w;               // Lưu kết quả cộng trung gian và W[t] cuối cùng
    reg [1:0] calc_cycle;           // 0: s1, 1: s2, 2: s3, 3: s4 (write back)
    reg calculation_active;         // Đánh dấu đang tính toán 4 chu kỳ

    // Các tín hiệu dây kết nối
    wire [31:0] mem_out_t_minus_16;
    wire [31:0] mem_out_t_minus_15;
    wire [31:0] mem_out_t_minus_7;
    wire [31:0] mem_out_t_minus_2;

    wire [3:0] addr_t_minus_16;
    wire [3:0] addr_t_minus_15;
    wire [3:0] addr_t_minus_7;
    wire [3:0] addr_t_minus_2;
    wire [3:0] write_addr;

    wire [31:0] sigma0_result;
    wire [31:0] sigma1_result;

    wire [31:0] adder_in_a;         // Đầu vào A của bộ cộng
    wire [31:0] adder_in_b;         // Đầu vào B của bộ cộng
    wire [31:0] adder_sum_out;      // Kết quả từ bộ cộng

    // --- Tính toán địa chỉ Memory (Modulo 16) ---
    assign addr_t_minus_16 = round_t[3:0];           // W[t-16] = t mod 16
    assign addr_t_minus_15 = (round_t - 6'd15) & 4'hF;// (t-15) mod 16
    assign addr_t_minus_7  = (round_t - 6'd7) & 4'hF;// (t-7) mod 16
    assign addr_t_minus_2  = (round_t - 6'd2) & 4'hF;// (t-2) mod 16
    assign write_addr      = addr_t_minus_16;        // Ghi đè lên W[t-16]

    // --- Đọc dữ liệu từ Memory ---
    assign mem_out_t_minus_16 = W_memory[addr_t_minus_16];
    assign mem_out_t_minus_15 = W_memory[addr_t_minus_15];
    assign mem_out_t_minus_7  = W_memory[addr_t_minus_7];
    assign mem_out_t_minus_2  = W_memory[addr_t_minus_2];

    // --- Khởi tạo các hàm Sigma ---
    sigma0_func_schedule u_sigma0 (.x(mem_out_t_minus_15), .out(sigma0_result));
    sigma1_func_schedule u_sigma1 (.x(mem_out_t_minus_2),  .out(sigma1_result));

    // --- Khởi tạo bộ cộng 32-bit ---
    adder_32bit u_adder (.a(adder_in_a), .b(adder_in_b), .sum(adder_sum_out));

    // --- Logic chọn đầu vào cho bộ cộng (Combinational) ---
    assign adder_in_a = (calculation_active && calc_cycle == 2'b00) ? mem_out_t_minus_16 : // Cycle 0: W[t-16]
                        (calculation_active && (calc_cycle == 2'b01 || calc_cycle == 2'b10)) ? reg_w : // Cycle 1, 2: reg_w cũ
                        32'b0; // Không dùng ở cycle 3 hoặc khi không active

    assign adder_in_b = (calculation_active && calc_cycle == 2'b00) ? sigma0_result :      // Cycle 0: sigma0(W[t-15])
                        (calculation_active && calc_cycle == 2'b01) ? mem_out_t_minus_7 :  // Cycle 1: W[t-7]
                        (calculation_active && calc_cycle == 2'b10) ? sigma1_result :      // Cycle 2: sigma1(W[t-2])
                        32'b0; // Không dùng ở cycle 3 hoặc khi không active

    // --- Logic điều khiển và cập nhật trạng thái (Sequential) ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            calc_cycle <= 2'b00;
            reg_w <= 32'b0;
            calculation_active <= 1'b0;
            // Không reset W_memory để tránh lãng phí tài nguyên, sẽ được ghi đè khi cần
        end else begin
            // --- Ghi dữ liệu đầu vào (M[i]) vào memory ---
            if (write_enable_in) begin
                W_memory[message_word_addr] <= message_word_in;
            end

            // --- Tính toán W[t] cho t >= 16 ---
            if (round_t >= 6'd16) 
            begin
                if (!calculation_active) begin // Bắt đầu tính toán cho round mới
                    calculation_active <= 1'b1;
                    calc_cycle <= 2'b00; // Khởi đầu từ cycle 0
                end 

                else 
                    begin // Đang trong quá trình tính toán
                    // Cập nhật reg_w với kết quả từ bộ cộng của chu kỳ trước
                    if (calc_cycle == 2'b00 || calc_cycle == 2'b01 || calc_cycle == 2'b10) begin
                        reg_w <= adder_sum_out;
                    end

                    // Chuyển sang chu kỳ tiếp theo
                    case (calc_cycle)
                        2'b00: begin
                            calc_cycle <= 2'b01;
                            $display("[%0t] Calculating W[%0d]:", $time, round_t);
                            $display("  W[t-16] = 0x%h", mem_out_t_minus_16);
                            $display("  W[t-15] = 0x%h", mem_out_t_minus_15);
                            $display("  W[t-7]  = 0x%h", mem_out_t_minus_7);
                            $display("  W[t-2]  = 0x%h", mem_out_t_minus_2);
                            $display("  σ0(W[t-15]) = 0x%h", sigma0_result);
                            $display("  σ1(W[t-2])  = 0x%h", sigma1_result);
                        end
                        2'b01: calc_cycle <= 2'b10;
                        2'b10: calc_cycle <= 2'b11;
                        2'b11: begin
                            if (!write_enable_in) begin
                                W_memory[write_addr] <= reg_w;
                                $display("[%0t] Writing W[%0d] = 0x%h to memory at addr %0d", $time, round_t, reg_w, write_addr);
                            end
                            calc_cycle <= 2'b00;
                            calculation_active <= 1'b0;
                            
                        end
                        default: begin
                            calc_cycle <= 2'b00;
                            calculation_active <= 1'b0;
                        end
                    endcase
                end
            end 

            else 
            begin // round_t < 16
                calculation_active <= 1'b0;
                calc_cycle <= 2'b00;
            end
        end
    end

    // --- Logic chọn đầu ra Wt_out (Combinational) ---
    assign Wt_out = (round_t < 6'd16) ? W_memory[addr_t_minus_16] : reg_w;

endmodule

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

    wire [31:0] Wt_out_dut;

    // --- Instantiate DUT ---
    message_scheduler uut (
        .clk(clk),
        .reset_n(reset_n),
        .start_new_block(start_new_block_tb),
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
