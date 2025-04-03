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
    assign addr_t_minus_15 = (round_t - 6'd1) & 4'hF;// (t-1) mod 16
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
            if (round_t >= 6'd16) begin
                if (!calculation_active) begin // Bắt đầu tính toán cho round mới
                    calculation_active <= 1'b1;
                    calc_cycle <= 2'b00; // Khởi đầu từ cycle 0
                end else begin // Đang trong quá trình tính toán
                    // Cập nhật reg_w với kết quả từ bộ cộng của chu kỳ trước
                    if (calc_cycle == 2'b00 || calc_cycle == 2'b01 || calc_cycle == 2'b10) begin
                        reg_w <= adder_sum_out;
                        $display("[%0t] Updated reg_w = 0x%h at cycle %0d", $time, adder_sum_out, calc_cycle);
                    end

                    // Chuyển sang chu kỳ tiếp theo
                    case (calc_cycle)
                        2'b00: calc_cycle <= 2'b01; // Cycle 0 -> 1
                        2'b01: calc_cycle <= 2'b10; // Cycle 1 -> 2
                        2'b10: calc_cycle <= 2'b11; // Cycle 2 -> 3 (write back)
                        2'b11: begin
                            if (!write_enable_in) begin
                                W_memory[write_addr] <= reg_w;
                                $display("[%0t] Writing W[%0d] = 0x%h to memory at addr %0d", $time, round_t, reg_w, write_addr);
                            end
                            calc_cycle <= 2'b00; // Reset về cycle 0
                            calculation_active <= 1'b0; // Kết thúc tính toán
                        end
                        default: begin
                            calc_cycle <= 2'b00;
                            calculation_active <= 1'b0;
                        end
                    endcase
                end
            end else begin // round_t < 16
                calculation_active <= 1'b0;
                calc_cycle <= 2'b00;
            end
        end
    end

    // --- Logic chọn đầu ra Wt_out (Combinational) ---
    assign Wt_out = (round_t < 6'd16) ? W_memory[addr_t_minus_16] : reg_w;

endmodule