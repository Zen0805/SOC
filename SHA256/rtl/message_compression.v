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

endmodule
//-----------------------------------------------------------------------------
// Module: ch_func
// Chức năng: Tính hàm Ch(x, y, z) = (x AND y) XOR (NOT x AND z)
//-----------------------------------------------------------------------------
module ch_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);
    assign out = (x & y) ^ (~x & z);
endmodule

//-----------------------------------------------------------------------------
// Module: maj_func
// Chức năng: Tính hàm Maj(x, y, z) = (x AND y) XOR (x AND z) XOR (y AND z)
//-----------------------------------------------------------------------------
module maj_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);
    assign out = (x & y) ^ (x & z) ^ (y & z);
endmodule

//-----------------------------------------------------------------------------
// Module: sigma0_comp_func  // Khác với sigma0_func_schedule
// Chức năng: Tính hàm Sigma0 (Σ₀) của SHA-256 (dùng trong compression)
//            Σ₀(x) = ROTR²(x) ⊕ ROTR¹³(x) ⊕ ROTR²²(x)
//-----------------------------------------------------------------------------
module sigma0_comp_func (
    input wire [31:0] x,
    output wire [31:0] out
);
    wire [31:0] rotr2_x  = {x[1:0],   x[31:2]};
    wire [31:0] rotr13_x = {x[12:0], x[31:13]};
    wire [31:0] rotr22_x = {x[21:0], x[31:22]};
    assign out = rotr2_x ^ rotr13_x ^ rotr22_x;
endmodule

//-----------------------------------------------------------------------------
// Module: sigma1_comp_func  // Khác với sigma1_func_schedule
// Chức năng: Tính hàm Sigma1 (Σ₁) của SHA-256 (dùng trong compression)
//            Σ₁(x) = ROTR⁶(x) ⊕ ROTR¹¹(x) ⊕ ROTR²⁵(x)
//-----------------------------------------------------------------------------
module sigma1_comp_func (
    input wire [31:0] x,
    output wire [31:0] out
);
    wire [31:0] rotr6_x  = {x[5:0],  x[31:6]};
    wire [31:0] rotr11_x = {x[10:0], x[31:11]};
    wire [31:0] rotr25_x = {x[24:0], x[31:25]};
    assign out = rotr6_x ^ rotr11_x ^ rotr25_x;
endmodule

//-----------------------------------------------------------------------------
// Module: message_compression_folded
// Tác giả: Hợp tác cùng bạn
// Chức năng: Thực hiện Message Compression của SHA-256 theo kiến trúc gấp.
//            Sử dụng 1 adder, 8 thanh ghi a-h, thực hiện 1 vòng trong 7 chu kỳ.
//            Tuân thủ Hình 3 và Bảng 1 trong paper.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Module: message_compression_folded
// Tác giả: Hợp tác cùng bạn
// Chức năng: Thực hiện Message Compression của SHA-256 theo kiến trúc gấp.
//            Sử dụng 1 adder, 8 thanh ghi a-h, thực hiện 1 vòng trong 7 chu kỳ.
//            Tuân thủ Hình 3 và Bảng 1 trong paper.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Module: message_compression_folded
// Tác giả: Hợp tác cùng bạn
// Chức năng: Thực hiện Message Compression của SHA-256 theo kiến trúc gấp.
//            Sử dụng 1 adder, 8 thanh ghi a-h, thực hiện 1 vòng trong 7 chu kỳ.
//            Tuân thủ Hình 3 và Bảng 1 trong paper.
//-----------------------------------------------------------------------------
module message_compression_folded (
    // --- Interface ---
    input wire          clk,
    input wire          rst_n,           // Reset tích cực thấp
    input wire          start,           // Bắt đầu xử lý 1 block 512-bit
    input wire [31:0]   Wt_in,           // W[t] từ message scheduler (cần ổn định trong 7 cycles/round)
    output wire [7:0][31:0] H_final_out, // Kết quả hash cuối cùng H0'-H7' (WIRE)
    output reg          busy,            // Báo hiệu đang xử lý
    output reg          done             // Báo hiệu hoàn thành (1 xung)
);

    // --- Parameters ---
    // State definitions
    localparam S_IDLE         = 4'd0;
    localparam S_INIT_LOAD    = 4'd1; // Nạp H0-H7 vào a-h (Giả định 1 cycle)
    localparam S_ROUND_START  = 4'd2; // Chuẩn bị cho vòng mới
    localparam S_ROUND_STEP1  = 4'd3; // h = h + Ch(e,f,g)
    localparam S_ROUND_STEP2  = 4'd4; // h = h + K[t]
    localparam S_ROUND_STEP3  = 4'd5; // h = h + Sigma1(e)
    localparam S_ROUND_STEP4  = 4'd6; // T1 = h + W[t]
    localparam S_ROUND_STEP5  = 4'd7; // d_new = d + T1
    localparam S_ROUND_STEP6  = 4'd8; // h_temp = Maj(a,b,c) + Sigma0(a)
    localparam S_ROUND_STEP7  = 4'd9; // a_new = T1 + h_temp; Cập nhật a-h
    localparam S_FINAL_ADD_ST = 4'd10;// Bắt đầu cộng kết quả cuối
    localparam S_FINAL_ADD    = 4'd11;// Thực hiện cộng H[i] + reg[i] (8 cycles)
    localparam S_DONE         = 4'd12;// Hoàn thành, tạo xung done

    // SHA-256 Initial Hash Values (H0-H7)
    localparam H0_INIT = 32'h6a09e667;
    localparam H1_INIT = 32'hbb67ae85;
    localparam H2_INIT = 32'h3c6ef372;
    localparam H3_INIT = 32'ha54ff53a;
    localparam H4_INIT = 32'h510e527f;
    localparam H5_INIT = 32'h9b05688c;
    localparam H6_INIT = 32'h1f83d9ab;
    localparam H7_INIT = 32'h5be0cd19;

    // --- Internal Registers ---
    reg [3:0]  state, next_state;
    reg [31:0] reg_a, reg_b, reg_c, reg_d, reg_e, reg_f, reg_g, reg_h; // Working variables
    reg [31:0] H_reg [7:0];           // Lưu trữ H0-H7 ban đầu hoặc kết quả trung gian
    reg [5:0]  round_counter;         // Đếm vòng 0-63
    reg [3:0]  step_counter;          // Đếm bước trong INIT, ROUND, FINAL_ADD

    // Temporary registers for intermediate calculations (theo Table 1)
    reg [31:0] h_temp;                // Lưu kết quả cộng dồn cho T1 / T2 tạm
    reg [31:0] T1_reg;                // Lưu T1 = h + Sigma1(e) + Ch(e,f,g) + K[t] + W[t]
    reg [31:0] d_new_reg;             // Lưu d + T1 (sẽ thành e mới)
    reg [31:0] a_new_reg;             // Lưu T1 + T2 (sẽ thành a mới)
    // reg [31:0] final_sum_temp;     // Không cần nữa

    // --- Internal Wires ---
    wire [31:0] Kt;                   // Hằng số vòng K[t]
    wire [31:0] ch_out;
    wire [31:0] maj_out;
    wire [31:0] sigma0_out;
    wire [31:0] sigma1_out;
    wire [31:0] adder_in_a;
    wire [31:0] adder_in_b;
    wire [31:0] adder_sum_out;

    // --- Instantiate Logic Functions ---
    ch_func u_ch (.x(reg_e), .y(reg_f), .z(reg_g), .out(ch_out));
    maj_func u_maj (.x(reg_a), .y(reg_b), .z(reg_c), .out(maj_out));
    sigma0_comp_func u_sigma0 (.x(reg_a), .out(sigma0_out));
    sigma1_comp_func u_sigma1 (.x(reg_e), .out(sigma1_out));

    // --- Instantiate Single Adder ---
    adder_32bit u_adder (.a(adder_in_a), .b(adder_in_b), .sum(adder_sum_out));

    // --- KH Block: K[t] Constants (Combinational) ---
    assign Kt = (round_counter == 6'd0)  ? 32'h428a2f98 :
                (round_counter == 6'd1)  ? 32'h71374491 :
                (round_counter == 6'd2)  ? 32'hb5c0fbcf :
                (round_counter == 6'd3)  ? 32'he9b5dba5 :
                (round_counter == 6'd4)  ? 32'h3956c25b :
                (round_counter == 6'd5)  ? 32'h59f111f1 :
                (round_counter == 6'd6)  ? 32'h923f82a4 :
                (round_counter == 6'd7)  ? 32'hab1c5ed5 :
                (round_counter == 6'd8)  ? 32'hd807aa98 :
                (round_counter == 6'd9)  ? 32'h12835b01 :
                (round_counter == 6'd10) ? 32'h243185be :
                (round_counter == 6'd11) ? 32'h550c7dc3 :
                (round_counter == 6'd12) ? 32'h72be5d74 :
                (round_counter == 6'd13) ? 32'h80deb1fe :
                (round_counter == 6'd14) ? 32'h9bdc06a7 :
                (round_counter == 6'd15) ? 32'hc19bf174 :
                (round_counter == 6'd16) ? 32'he49b69c1 :
                (round_counter == 6'd17) ? 32'hefbe4786 :
                (round_counter == 6'd18) ? 32'h0fc19dc6 :
                (round_counter == 6'd19) ? 32'h240ca1cc :
                (round_counter == 6'd20) ? 32'h2de92c6f :
                (round_counter == 6'd21) ? 32'h4a7484aa :
                (round_counter == 6'd22) ? 32'h5cb0a9dc :
                (round_counter == 6'd23) ? 32'h76f988da :
                (round_counter == 6'd24) ? 32'h983e5152 :
                (round_counter == 6'd25) ? 32'ha831c66d :
                (round_counter == 6'd26) ? 32'hb00327c8 :
                (round_counter == 6'd27) ? 32'hbf597fc7 :
                (round_counter == 6'd28) ? 32'hc6e00bf3 :
                (round_counter == 6'd29) ? 32'hd5a79147 :
                (round_counter == 6'd30) ? 32'h06ca6351 :
                (round_counter == 6'd31) ? 32'h14292967 :
                (round_counter == 6'd32) ? 32'h27b70a85 :
                (round_counter == 6'd33) ? 32'h2e1b2138 :
                (round_counter == 6'd34) ? 32'h4d2c6dfc :
                (round_counter == 6'd35) ? 32'h53380d13 :
                (round_counter == 6'd36) ? 32'h650a7354 :
                (round_counter == 6'd37) ? 32'h766a0abb :
                (round_counter == 6'd38) ? 32'h81c2c92e :
                (round_counter == 6'd39) ? 32'h92722c85 :
                (round_counter == 6'd40) ? 32'ha2bfe8a1 :
                (round_counter == 6'd41) ? 32'ha81a664b :
                (round_counter == 6'd42) ? 32'hc24b8b70 :
                (round_counter == 6'd43) ? 32'hc76c51a3 :
                (round_counter == 6'd44) ? 32'hd192e819 :
                (round_counter == 6'd45) ? 32'hd6990624 :
                (round_counter == 6'd46) ? 32'hf40e3585 :
                (round_counter == 6'd47) ? 32'h106aa070 :
                (round_counter == 6'd48) ? 32'h19a4c116 :
                (round_counter == 6'd49) ? 32'h1e376c08 :
                (round_counter == 6'd50) ? 32'h2748774c :
                (round_counter == 6'd51) ? 32'h34b0bcb5 :
                (round_counter == 6'd52) ? 32'h391c0cb3 :
                (round_counter == 6'd53) ? 32'h4ed8aa4a :
                (round_counter == 6'd54) ? 32'h5b9cca4f :
                (round_counter == 6'd55) ? 32'h682e6ff3 :
                (round_counter == 6'd56) ? 32'h748f82ee :
                (round_counter == 6'd57) ? 32'h78a5636f :
                (round_counter == 6'd58) ? 32'h84c87814 :
                (round_counter == 6'd59) ? 32'h8cc70208 :
                (round_counter == 6'd60) ? 32'h90befffa :
                (round_counter == 6'd61) ? 32'ha4506ceb :
                (round_counter == 6'd62) ? 32'hbef9a3f7 :
                (round_counter == 6'd63) ? 32'hc67178f2 :
                32'h00000000; // Giá trị mặc định

    // --- Adder Input Selection Logic (Combinational) ---
    assign adder_in_a = (state == S_ROUND_STEP1) ? reg_h :
                        (state == S_ROUND_STEP2) ? h_temp :
                        (state == S_ROUND_STEP3) ? h_temp :
                        (state == S_ROUND_STEP4) ? h_temp :
                        (state == S_ROUND_STEP5) ? reg_d :
                        (state == S_ROUND_STEP6) ? maj_out :
                        (state == S_ROUND_STEP7) ? T1_reg :
                        (state == S_FINAL_ADD)   ? H_reg[step_counter] :
                        32'b0;

    assign adder_in_b = (state == S_ROUND_STEP1) ? ch_out :
                        (state == S_ROUND_STEP2) ? Kt :
                        (state == S_ROUND_STEP3) ? sigma1_out :
                        (state == S_ROUND_STEP4) ? Wt_in :
                        (state == S_ROUND_STEP5) ? T1_reg :
                        (state == S_ROUND_STEP6) ? sigma0_out :
                        (state == S_ROUND_STEP7) ? h_temp :
                        (state == S_FINAL_ADD)   ? (step_counter == 4'd0 ? reg_a :
                                                    step_counter == 4'd1 ? reg_b :
                                                    step_counter == 4'd2 ? reg_c :
                                                    step_counter == 4'd3 ? reg_d :
                                                    step_counter == 4'd4 ? reg_e :
                                                    step_counter == 4'd5 ? reg_f :
                                                    step_counter == 4'd6 ? reg_g :
                                                    reg_h) :
                        32'b0;

    // --- State Machine Logic (Sequential) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            reg_a <= 32'b0; reg_b <= 32'b0; reg_c <= 32'b0; reg_d <= 32'b0;
            reg_e <= 32'b0; reg_f <= 32'b0; reg_g <= 32'b0; reg_h <= 32'b0;
            H_reg[0] <= 32'b0; H_reg[1] <= 32'b0; H_reg[2] <= 32'b0; H_reg[3] <= 32'b0;
            H_reg[4] <= 32'b0; H_reg[5] <= 32'b0; H_reg[6] <= 32'b0; H_reg[7] <= 32'b0;
            round_counter <= 6'b0;
            step_counter <= 4'b0;
            h_temp <= 32'b0;
            T1_reg <= 32'b0;
            d_new_reg <= 32'b0;
            a_new_reg <= 32'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            state <= next_state;
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        H_reg[0] <= H0_INIT; H_reg[1] <= H1_INIT;
                        H_reg[2] <= H2_INIT; H_reg[3] <= H3_INIT;
                        H_reg[4] <= H4_INIT; H_reg[5] <= H5_INIT;
                        H_reg[6] <= H6_INIT; H_reg[7] <= H7_INIT;
                        step_counter <= 4'd0;
                        busy <= 1'b1;
                    end
                end

                S_INIT_LOAD: begin
                    // *** Nạp trực tiếp trong 1 cycle ***
                    reg_a <= H_reg[0]; reg_b <= H_reg[1];
                    reg_c <= H_reg[2]; reg_d <= H_reg[3];
                    reg_e <= H_reg[4]; reg_f <= H_reg[5];
                    reg_g <= H_reg[6]; reg_h <= H_reg[7];
                    round_counter <= 6'd0;
                end

                S_ROUND_START: begin
                    // No register updates needed here
                end

                S_ROUND_STEP1: h_temp <= adder_sum_out;
                S_ROUND_STEP2: h_temp <= adder_sum_out;
                S_ROUND_STEP3: h_temp <= adder_sum_out;
                S_ROUND_STEP4: T1_reg <= adder_sum_out;
                S_ROUND_STEP5: d_new_reg <= adder_sum_out;
                S_ROUND_STEP6: h_temp <= adder_sum_out;
                S_ROUND_STEP7: begin
                    a_new_reg <= adder_sum_out;
                    reg_h <= reg_g;
                    reg_g <= reg_f;
                    reg_f <= reg_e;
                    reg_e <= d_new_reg;
                    reg_d <= reg_c;
                    reg_c <= reg_b;
                    reg_b <= reg_a;
                    reg_a <= a_new_reg;
                    if (round_counter < 6'd63) begin
                        round_counter <= round_counter + 1;
                    end
                end

                S_FINAL_ADD_ST: begin
                    step_counter <= 4'd0;
                end

                S_FINAL_ADD: begin
                    H_reg[step_counter] <= adder_sum_out;
                    if (step_counter < 4'd7) begin
                        step_counter <= step_counter + 1;
                    end
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // --- Next State Logic (Combinational) ---
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:         if (start) next_state = S_INIT_LOAD;
            S_INIT_LOAD:    next_state = S_ROUND_START;
            S_ROUND_START:  next_state = S_ROUND_STEP1;
            S_ROUND_STEP1:  next_state = S_ROUND_STEP2;
            S_ROUND_STEP2:  next_state = S_ROUND_STEP3;
            S_ROUND_STEP3:  next_state = S_ROUND_STEP4;
            S_ROUND_STEP4:  next_state = S_ROUND_STEP5;
            S_ROUND_STEP5:  next_state = S_ROUND_STEP6;
            S_ROUND_STEP6:  next_state = S_ROUND_STEP7;
            S_ROUND_STEP7:  if (round_counter == 6'd63) next_state = S_FINAL_ADD_ST;
                            else next_state = S_ROUND_START;
            S_FINAL_ADD_ST: next_state = S_FINAL_ADD;
            S_FINAL_ADD:    if (step_counter == 4'd7) next_state = S_DONE;
                            // else next_state = S_FINAL_ADD; // Giữ nguyên state
            S_DONE:         next_state = S_IDLE;
            default:        next_state = S_IDLE;
        endcase
    end

    // --- Output Assignment ---
    // Gán từng phần tử của mảng để đảm bảo tương thích
    assign H_final_out[0] = H_reg[0];
    assign H_final_out[1] = H_reg[1];
    assign H_final_out[2] = H_reg[2];
    assign H_final_out[3] = H_reg[3];
    assign H_final_out[4] = H_reg[4];
    assign H_final_out[5] = H_reg[5];
    assign H_final_out[6] = H_reg[6];
    assign H_final_out[7] = H_reg[7];

endmodule