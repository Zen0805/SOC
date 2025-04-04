//-----------------------------------------------------------------------------
// Module: sha256_compression
// Tác giả: tao
// Chức năng: Thực hiện 64 vòng tính toán nén của SHA-256.
//            Sử dụng 8 thanh ghi a-h, cập nhật theo kiến trúc gấp (Fig 3).
//            Tính toán dựa trên Wt và Kt cho mỗi vòng.
//-----------------------------------------------------------------------------
module sha256_compression (
    // --- Inputs ---
    input wire          clk,
    input wire          reset_n,         // Reset tích cực thấp
    input wire          start,           // Bắt đầu tính toán block mới
    input wire [31:0]   H_in [0:7],      // Giá trị hash ban đầu (H0-H7) hoặc từ block trước
    input wire [31:0]   Wt_in,           // Message word W[t] từ message scheduler
    input wire [5:0]    round_t,         // Vòng lặp hiện tại (0-63), dùng để chọn Kt

    // --- Outputs ---
    output reg [31:0]   H_out [0:7],     // Kết quả hash cuối cùng của block
    output reg          busy,            // Báo hiệu đang trong quá trình tính toán
    output reg          done             // Báo hiệu đã hoàn thành 64 vòng
);

    // --- Hằng số K[0..63] của SHA-256 ---
    localparam [31:0] K[0:63] = {
        32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
        32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
        32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
        32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
        32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
        32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
        32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
        32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
    };

    // --- Thanh ghi trạng thái a-h ---
    reg [31:0] a_reg, b_reg, c_reg, d_reg, e_reg, f_reg, g_reg, h_reg;

    // --- Lưu trữ giá trị H ban đầu ---
    reg [31:0] H_initial [0:7];

    // --- Trạng thái điều khiển ---
    typedef enum logic [1:0] {
        IDLE,       // Chờ start
        COMPUTE,    // Đang thực hiện 64 vòng
        ADD_FINAL,  // Cộng kết quả cuối cùng
        DONE_STATE  // Hoàn thành, chờ reset hoặc start mới
    } state_t;
    reg state, next_state;

    // --- Tín hiệu trung gian cho tính toán trong 1 vòng ---
    wire [31:0] ch_result;
    wire [31:0] maj_result;
    wire [31:0] s0_result; // Sigma0(a)
    wire [31:0] s1_result; // Sigma1(e)
    wire [31:0] Kt;        // Hằng số K[t] cho vòng hiện tại
    wire [31:0] temp1;
    wire [31:0] temp2;
    wire [31:0] a_next;
    wire [31:0] e_next;

    // --- Instantiate các hàm logic SHA-256 ---
    ch_func u_ch (.x(e_reg), .y(f_reg), .z(g_reg), .out(ch_result));
    maj_func u_maj (.x(a_reg), .y(b_reg), .z(c_reg), .out(maj_result));
    sigma0_func_compression u_s0 (.x(a_reg), .out(s0_result));
    sigma1_func_compression u_s1 (.x(e_reg), .out(s1_result));

    // --- Lấy hằng số Kt ---
    assign Kt = K[round_t]; // Lấy Kt dựa vào round_t từ message scheduler

    // --- Tính toán tổ hợp các giá trị tạm thời (Theo Steps 1-6) ---
    // temp1 = h + Ch(e,f,g) + Σ₁(e) + Wt + Kt (Kết hợp step 1-4)
    assign temp1 = h_reg + ch_result + s1_result + Wt_in + Kt;
    // temp2 = Σ₀(a) + Maj(a,b,c) (Theo step 6, phần đầu của step 7a)
    assign temp2 = s0_result + maj_result;

    // --- Tính toán giá trị tiếp theo cho a và e (Theo Step 7) ---
    assign a_next = temp1 + temp2;
    assign e_next = d_reg + temp1; // d + temp1 (temp1 đã bao gồm h + ...)

    // --- Logic trạng thái tuần tự (Cập nhật thanh ghi và state) ---
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            a_reg <= 32'b0; b_reg <= 32'b0; c_reg <= 32'b0; d_reg <= 32'b0;
            e_reg <= 32'b0; f_reg <= 32'b0; g_reg <= 32'b0; h_reg <= 32'b0;
            busy <= 1'b0;
            done <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                 H_initial[i] <= 32'b0;
                 H_out[i] <= 32'b0;
            end
        end else begin
            state <= next_state; // Cập nhật trạng thái
            busy <= (next_state == COMPUTE || next_state == ADD_FINAL); // Busy khi đang tính hoặc cộng
            done <= (next_state == DONE_STATE); // Done khi ở trạng thái DONE_STATE

            case (state)
                IDLE: begin
                    if (start) begin
                        // Nạp giá trị H ban đầu vào thanh ghi a-h và H_initial
                        a_reg <= H_in[0]; H_initial[0] <= H_in[0];
                        b_reg <= H_in[1]; H_initial[1] <= H_in[1];
                        c_reg <= H_in[2]; H_initial[2] <= H_in[2];
                        d_reg <= H_in[3]; H_initial[3] <= H_in[3];
                        e_reg <= H_in[4]; H_initial[4] <= H_in[4];
                        f_reg <= H_in[5]; H_initial[5] <= H_in[5];
                        g_reg <= H_in[6]; H_initial[6] <= H_in[6];
                        h_reg <= H_in[7]; H_initial[7] <= H_in[7];
                        //$display("[%0t] COMPRESSION: Started. Loaded H0-H7. Round %0d.", $time, round_t);
                    end
                end

                COMPUTE: begin
                    // Thực hiện cập nhật đồng thời 8 thanh ghi theo Step 7
                    a_reg <= a_next;      // a = temp1 + temp2
                    b_reg <= a_reg;       // b = a
                    c_reg <= b_reg;       // c = b
                    d_reg <= c_reg;       // d = c
                    e_reg <= e_next;      // e = d + temp1
                    f_reg <= e_reg;       // f = e
                    g_reg <= f_reg;       // g = f
                    h_reg <= g_reg;       // h = g
                    /*
                    $display("[%0t] COMPRESSION: Round %0d", $time, round_t);
                    $display("  Wt=%h, Kt=%h", Wt_in, Kt);
                    $display("  a=%h, b=%h, c=%h, d=%h", a_reg, b_reg, c_reg, d_reg);
                    $display("  e=%h, f=%h, g=%h, h=%h", e_reg, f_reg, g_reg, h_reg);
                    $display("  Ch=%h, Maj=%h, S0=%h, S1=%h", ch_result, maj_result, s0_result, s1_result);
                    $display("  T1=%h, T2=%h", temp1, temp2);
                    $display("  a_next=%h, e_next=%h", a_next, e_next);
                    */
                end

                ADD_FINAL: begin
                     // Cộng giá trị H ban đầu vào kết quả cuối của a-h
                     H_out[0] <= a_reg + H_initial[0];
                     H_out[1] <= b_reg + H_initial[1];
                     H_out[2] <= c_reg + H_initial[2];
                     H_out[3] <= d_reg + H_initial[3];
                     H_out[4] <= e_reg + H_initial[4];
                     H_out[5] <= f_reg + H_initial[5];
                     H_out[6] <= g_reg + H_initial[6];
                     H_out[7] <= h_reg + H_initial[7];
                     //$display("[%0t] COMPRESSION: Final Addition Complete.", $time);
                end

                DONE_STATE: begin
                     // Giữ nguyên giá trị H_out, chờ start mới
                     // Có thể reset thanh ghi a-h ở đây nếu muốn
                end

                default: state <= IDLE; // An toàn là trên hết

            endcase
        end
    end

    // --- Logic chuyển trạng thái tổ hợp ---
    always_comb begin
        next_state = state; // Mặc định giữ nguyên trạng thái
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = COMPUTE;
                end
            end
            COMPUTE: begin
                // Cần tín hiệu round_t từ bên ngoài (ví dụ: từ controller chính)
                // để biết khi nào hoàn thành 64 vòng.
                if (round_t == 6'd63) begin // Nếu đây là vòng cuối cùng
                    next_state = ADD_FINAL; // Chuyển sang cộng kết quả ở clock tiếp theo
                end else begin
                    next_state = COMPUTE; // Tiếp tục tính vòng tiếp theo
                end
            end
            ADD_FINAL: begin
                next_state = DONE_STATE; // Sau khi cộng xong, chuyển sang DONE
            end
            DONE_STATE: begin
                if (start) begin // Nếu có tín hiệu start mới (cho block tiếp theo)
                    next_state = COMPUTE; // Bắt đầu lại quá trình tính toán
                end else begin
                    next_state = IDLE; // Quay về IDLE chờ nếu không có start
                end
            end
            default: next_state = IDLE;
        endcase
    end

endmodule