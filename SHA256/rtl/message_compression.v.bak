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



module ch_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);
    assign out = (x & y) ^ (~x & z);
endmodule



module maj_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);
    assign out = (x & y) ^ (x & z) ^ (y & z);
endmodule



module sigma0_comp_func (
    input wire [31:0] x,
    output wire [31:0] out
);
    wire [31:0] rotr2_x  = {x[1:0],   x[31:2]};
    wire [31:0] rotr13_x = {x[12:0], x[31:13]};
    wire [31:0] rotr22_x = {x[21:0], x[31:22]};
    assign out = rotr2_x ^ rotr13_x ^ rotr22_x;
endmodule



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
//            Sử dụng 1 adder, 8 thanh ghi a-h.
//            FIX: Added S_ROUND_UPDATE state (8 cycles/round).
//            FIX: Use literal hex values for H_INIT assignments.
//-----------------------------------------------------------------------------

module message_compression_folded (
    // --- Interface ---
    input wire          clk,
    input wire          rst_n,           // Reset tích cực thấp
    input wire          start,           // Bắt đầu xử lý 1 block 512-bit
    input wire [31:0]   Wt_in,           // W[t] (ổn định trong 8 cycles/round)
    output wire [7:0][31:0] H_final_out, // Kết quả hash cuối cùng H0'-H7' (WIRE)
    output reg          busy,            // Báo hiệu đang xử lý
    output reg          done             // Báo hiệu hoàn thành (1 xung)
);

    // --- Parameters ---
    // State definitions (Keep for reference, logic uses literals if needed elsewhere)
    localparam S_IDLE         = 4'd0;
    localparam S_INIT_LOAD    = 4'd1;
    localparam S_ROUND_START  = 4'd2;
    localparam S_ROUND_STEP1  = 4'd3; // h = h + Ch
    localparam S_ROUND_STEP2  = 4'd4; // h = h + K
    localparam S_ROUND_STEP3  = 4'd5; // h = h + S1
    localparam S_ROUND_STEP4  = 4'd6; // T1 = h + W
    localparam S_ROUND_STEP5  = 4'd7; // d_new = d + T1
    localparam S_ROUND_STEP6  = 4'd8; // h_temp = Maj + S0 (T2)
    localparam S_ROUND_STEP7  = 4'd9; // Calculate a_new = T1 + T2
    localparam S_ROUND_UPDATE = 4'd10; // *** NEW STATE: Update a-h ***
    localparam S_FINAL_ADD_ST = 4'd11; // Renumbered
    localparam S_FINAL_ADD    = 4'd12; // Renumbered
    localparam S_DONE         = 4'd13; // Renumbered

    // SHA-256 Initial Hash Values (Keep definitions for reference)
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
    reg [31:0] reg_a, reg_b, reg_c, reg_d, reg_e, reg_f, reg_g, reg_h;
    reg [31:0] H_reg [7:0];
    reg [5:0]  round_counter;
    reg [3:0]  step_counter;

    // Temporary registers
    reg [31:0] h_temp;    // Holds intermediate sum for T1 / holds T2
    reg [31:0] T1_reg;    // Holds final T1
    reg [31:0] d_new_reg; // Holds calculated new 'e' (d+T1)
    reg [31:0] a_new_calc;// Holds calculated new 'a' (T1+T2)

    // --- Internal Wires ---
    wire [31:0] Kt;
    wire [31:0] ch_out;
    wire [31:0] maj_out;
    wire [31:0] sigma0_out;
    wire [31:0] sigma1_out;
    wire [31:0] adder_in_a;
    wire [31:0] adder_in_b;
    wire [31:0] adder_sum_out;

    // --- Instantiate Logic Functions & Adder ---
    ch_func u_ch (.x(reg_e), .y(reg_f), .z(reg_g), .out(ch_out));
    maj_func u_maj (.x(reg_a), .y(reg_b), .z(reg_c), .out(maj_out));
    sigma0_comp_func u_sigma0 (.x(reg_a), .out(sigma0_out));
    sigma1_comp_func u_sigma1 (.x(reg_e), .out(sigma1_out));
    adder_32bit u_adder (.a(adder_in_a), .b(adder_in_b), .sum(adder_sum_out));

    // --- KH Block: K[t] Constants ---
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
                32'h00000000;

    // --- Adder Input Selection Logic ---
    // Use literal values for states if necessary, but parameters might work here
    assign adder_in_a = (state == S_ROUND_STEP1) ? reg_h :
                        (state == S_ROUND_STEP2) ? h_temp :
                        (state == S_ROUND_STEP3) ? h_temp :
                        (state == S_ROUND_STEP4) ? h_temp :
                        (state == S_ROUND_STEP5) ? reg_d :
                        (state == S_ROUND_STEP6) ? maj_out :
                        (state == S_ROUND_STEP7) ? T1_reg :
                        (state == S_FINAL_ADD)   ? H_reg[step_counter] : // State 12
                        32'b0;

    assign adder_in_b = (state == S_ROUND_STEP1) ? ch_out :
                        (state == S_ROUND_STEP2) ? Kt :
                        (state == S_ROUND_STEP3) ? sigma1_out :
                        (state == S_ROUND_STEP4) ? Wt_in :
                        (state == S_ROUND_STEP5) ? T1_reg :
                        (state == S_ROUND_STEP6) ? sigma0_out :
                        (state == S_ROUND_STEP7) ? h_temp : // h_temp holds T2 here
                        (state == S_FINAL_ADD)   ? (step_counter == 4'd0 ? reg_a : // State 12
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
            // Use literal for state reset
            state <= 4'd0; // S_IDLE
            // Reset ALL registers
            reg_a <= 32'b0; reg_b <= 32'b0; reg_c <= 32'b0; reg_d <= 32'b0;
            reg_e <= 32'b0; reg_f <= 32'b0; reg_g <= 32'b0; reg_h <= 32'b0;
            H_reg[0] <= 32'b0; H_reg[1] <= 32'b0; H_reg[2] <= 32'b0; H_reg[3] <= 32'b0;
            H_reg[4] <= 32'b0; H_reg[5] <= 32'b0; H_reg[6] <= 32'b0; H_reg[7] <= 32'b0;
            round_counter <= 6'b0;
            step_counter <= 4'b0;
            h_temp <= 32'b0;
            T1_reg <= 32'b0;
            d_new_reg <= 32'b0;
            a_new_calc <= 32'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            state <= next_state;
            done <= 1'b0;

            // Use literal values for case labels
            case (state)
                4'd0: begin // S_IDLE
                    if (start) begin
                        // *** FIX: Use literal hex values for H_INIT ***
                        H_reg[0] <= 32'h6a09e667;
                        H_reg[1] <= 32'hbb67ae85;
                        H_reg[2] <= 32'h3c6ef372;
                        H_reg[3] <= 32'ha54ff53a;
                        H_reg[4] <= 32'h510e527f;
                        H_reg[5] <= 32'h9b05688c;
                        H_reg[6] <= 32'h1f83d9ab;
                        H_reg[7] <= 32'h5be0cd19;
                        step_counter <= 4'd0;
                        busy <= 1'b1;
                    end
                end

                4'd1: begin // S_INIT_LOAD
                    reg_a <= H_reg[0]; reg_b <= H_reg[1]; reg_c <= H_reg[2]; reg_d <= H_reg[3];
                    reg_e <= H_reg[4]; reg_f <= H_reg[5]; reg_g <= H_reg[6]; reg_h <= H_reg[7];
                    round_counter <= 6'd0;
                end

                4'd2: begin // S_ROUND_START
                    // No updates
                end

                4'd3: h_temp <= adder_sum_out; // S_ROUND_STEP1
                4'd4: h_temp <= adder_sum_out; // S_ROUND_STEP2
                4'd5: h_temp <= adder_sum_out; // S_ROUND_STEP3
                4'd6: T1_reg <= adder_sum_out; // S_ROUND_STEP4
                4'd7: d_new_reg <= adder_sum_out; // S_ROUND_STEP5
                4'd8: h_temp <= adder_sum_out; // S_ROUND_STEP6

                4'd9: begin // S_ROUND_STEP7: Calculate final 'a'
                    a_new_calc <= adder_sum_out;
                end

                4'd10: begin // S_ROUND_UPDATE: Perform ALL register updates
                    reg_a <= a_new_calc; reg_b <= reg_a; reg_c <= reg_b; reg_d <= reg_c;
                    reg_e <= d_new_reg; reg_f <= reg_e; reg_g <= reg_f; reg_h <= reg_g;
                    if (round_counter < 6'd63) begin
                        round_counter <= round_counter + 1;
                    end
                end

                4'd11: begin // S_FINAL_ADD_ST
                    step_counter <= 4'd0;
                end

                4'd12: begin // S_FINAL_ADD
                    H_reg[step_counter] <= adder_sum_out;
                    if (step_counter < 4'd7) begin
                        step_counter <= step_counter + 1;
                    end
                end

                4'd13: begin // S_DONE
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // --- Next State Logic (Combinational) ---
    always @(*) begin
        next_state = state;
        // Use literal values for case labels and assignments
        case (state)
            4'd0: if (start) next_state = 4'd1;   // S_IDLE -> S_INIT_LOAD
            4'd1: next_state = 4'd2;              // S_INIT_LOAD -> S_ROUND_START
            4'd2: next_state = 4'd3;              // S_ROUND_START -> S_ROUND_STEP1
            4'd3: next_state = 4'd4;              // S_ROUND_STEP1 -> S_ROUND_STEP2
            4'd4: next_state = 4'd5;              // S_ROUND_STEP2 -> S_ROUND_STEP3
            4'd5: next_state = 4'd6;              // S_ROUND_STEP3 -> S_ROUND_STEP4
            4'd6: next_state = 4'd7;              // S_ROUND_STEP4 -> S_ROUND_STEP5
            4'd7: next_state = 4'd8;              // S_ROUND_STEP5 -> S_ROUND_STEP6
            4'd8: next_state = 4'd9;              // S_ROUND_STEP6 -> S_ROUND_STEP7
            4'd9: next_state = 4'd10;             // S_ROUND_STEP7 -> S_ROUND_UPDATE
            4'd10: if (round_counter == 6'd63) next_state = 4'd11; // S_ROUND_UPDATE -> S_FINAL_ADD_ST
                   else next_state = 4'd2;                         // S_ROUND_UPDATE -> S_ROUND_START
            4'd11: next_state = 4'd12;            // S_FINAL_ADD_ST -> S_FINAL_ADD
            4'd12: if (step_counter == 4'd7) next_state = 4'd13; // S_FINAL_ADD -> S_DONE
            4'd13: next_state = 4'd0;             // S_DONE -> S_IDLE
            default: next_state = 4'd0;           // Default -> S_IDLE
        endcase
    end

    // --- Output Assignment ---
    assign H_final_out[0] = H_reg[0];
    assign H_final_out[1] = H_reg[1];
    assign H_final_out[2] = H_reg[2];
    assign H_final_out[3] = H_reg[3];
    assign H_final_out[4] = H_reg[4];
    assign H_final_out[5] = H_reg[5];
    assign H_final_out[6] = H_reg[6];
    assign H_final_out[7] = H_reg[7];

endmodule

`timescale 1ns / 1ps

module tb_message_compression_folded();

    // --- Testbench Signals ---
    reg         clk;
    reg         rst_n;
    reg         start_tb;
    reg  [31:0] Wt_in_tb;

    wire [7:0][31:0] H_final_out_dut;
    wire        busy_dut;
    wire        done_dut;

    // --- Instantiate DUT ---
    message_compression_folded uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_tb),
        .Wt_in(Wt_in_tb),
        .H_final_out(H_final_out_dut),
        .busy(busy_dut),
        .done(done_dut)
    );

    // --- Clock Generation ---
    parameter CLK_PERIOD = 10; // Clock period 10ns
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Test Sequence ---
    initial begin
        // 1. Initialize and Reset
        rst_n = 1'b0;
        start_tb = 1'b0;
        Wt_in_tb = 32'b0;
        $display("[%0t] Applying Reset...", $time);
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        $display("[%0t] Releasing Reset. Waiting for DUT...", $time);
        @(posedge clk);

        // 2. Start the compression
        $display("[%0t] Asserting Start signal.", $time);
        start_tb = 1'b1;
        @(posedge clk);
        start_tb = 1'b0; // Start is a pulse

        // Wait for initialization state(s) to pass
        // Wait until DUT state is S_ROUND_START (value 2)
        wait (uut.state == 4'd2);
        $display("[%0t] DUT Initialization complete. State: %h", $time, uut.state);


        // 3. Provide Wt_in and Monitor 64 rounds (8 cycles per round)
        $display("[%0t] Starting round simulation with intermediate value printing...", $time);
        for (integer t = 0; t < 64; t = t + 1) begin
            // Provide Wt for the current round 't'
            // *** Using Wt = t + 0x100 to match original Python example ***
            // *** Ensure Python script uses the same Wt sequence ***
            Wt_in_tb = t + 32'h100;
            $display("----------------------------------------------------------------------");
            $display("[%0t] V-Round %0d Start: Providing Wt_in = 0x%h", $time, t, Wt_in_tb);
            $display("  Input State: a=%h b=%h c=%h d=%h e=%h f=%h g=%h h=%h",
                     uut.reg_a, uut.reg_b, uut.reg_c, uut.reg_d, uut.reg_e, uut.reg_f, uut.reg_g, uut.reg_h);

            // Monitor the 8 steps within the round
            // Wait for Step 1 End (State 3 -> 4)
            wait (uut.state == 4'd4); @(posedge clk);
            $display("[%0t]   V-Step 1 End (h+Ch): h_temp = %h (State was 3)", $time, uut.h_temp);

            // Wait for Step 2 End (State 4 -> 5)
            wait (uut.state == 4'd5); @(posedge clk);
            $display("[%0t]   V-Step 2 End (h+K):  h_temp = %h (State was 4)", $time, uut.h_temp);

            // Wait for Step 3 End (State 5 -> 6)
            wait (uut.state == 4'd6); @(posedge clk);
            $display("[%0t]   V-Step 3 End (h+S1): h_temp = %h (State was 5)", $time, uut.h_temp);

            // Wait for Step 4 End (State 6 -> 7)
            wait (uut.state == 4'd7); @(posedge clk);
            $display("[%0t]   V-Step 4 End (h+W):  T1_reg = %h (State was 6)", $time, uut.T1_reg);

            // Wait for Step 5 End (State 7 -> 8)
            wait (uut.state == 4'd8); @(posedge clk);
            $display("[%0t]   V-Step 5 End (d+T1): d_new  = %h (State was 7)", $time, uut.d_new_reg);

            // Wait for Step 6 End (State 8 -> 9)
            wait (uut.state == 4'd9); @(posedge clk);
            $display("[%0t]   V-Step 6 End (Maj+S0):h_temp = %h (State was 8)", $time, uut.h_temp); // T2

            // Wait for Step 7 End (State 9 -> 10)
            wait (uut.state == 4'd10); @(posedge clk); // Wait for S_ROUND_UPDATE
            $display("[%0t]   V-Step 7 End (T1+T2):a_calc = %h (State was 9)", $time, uut.a_new_calc);

            // Wait for Update Step End (State 10 -> 2 or 11)
            wait (uut.state != 4'd10); @(posedge clk); // Wait until state changes FROM S_ROUND_UPDATE
            $display("[%0t] V-Round %0d End (After Update): a=%h b=%h c=%h d=%h e=%h f=%h g=%h h=%h", $time, t,
                     uut.reg_a, uut.reg_b, uut.reg_c, uut.reg_d, uut.reg_e, uut.reg_f, uut.reg_g, uut.reg_h);

             // Check if DUT state is correct after round update
             if (t < 63) begin
                 if (uut.state != 4'd2) $error("DUT state not S_ROUND_START (2) after round %0d update, it is %h", t, uut.state);
             end else begin // After round 63 update
                 if (uut.state != 4'd11) $error("DUT state not S_FINAL_ADD_ST (11) after round 63 update, it is %h", uut.state);
             end

        end // End of for loop (rounds)
        $display("----------------------------------------------------------------------");
        $display("[%0t] Finished providing Wt for 64 rounds.", $time);

        // 4. Wait for Final Addition and Done signal
        $display("[%0t] Waiting for final addition and done signal...", $time);
        // Monitor final addition steps (optional)
        if (uut.state == 4'd11) begin // Check if in S_FINAL_ADD_ST (11)
             $display("[%0t] Entering Final Add Stage.", $time);
             wait (uut.state == 4'd12); @(posedge clk); // Wait for S_FINAL_ADD (12)
             for (integer i = 0; i < 8; i = i + 1) begin
                 // Display value *before* it's potentially updated in the same cycle by the DUT
                 $display("[%0t]   Final Add Step %0d Start: H_reg[%0d]=%h, Reg=%h (State is %h)", $time, i, i, uut.H_reg[i],
                          (i==0 ? uut.reg_a : i==1 ? uut.reg_b : i==2 ? uut.reg_c : i==3 ? uut.reg_d :
                           i==4 ? uut.reg_e : i==5 ? uut.reg_f : i==6 ? uut.reg_g : uut.reg_h), uut.state);
                 if (i < 7) begin
                     wait (uut.step_counter == i+1); // Wait until DUT updates step counter
                     @(posedge clk); // Wait for the clock edge after step counter update
                 end else begin // Last step
                     wait (uut.state == 4'd13); // Wait for S_DONE (13)
                     @(posedge clk);
                 end
                 // Display value *after* DUT likely updated H_reg in the previous cycle
                 $display("[%0t]   Final Add Step %0d End:   H_reg[%0d]=%h", $time, i, i, uut.H_reg[i]);
             end
        end

        wait (done_dut == 1'b1);
        $display("[%0t] Done signal received.", $time);
        @(posedge clk); // Wait one more cycle for outputs to settle if needed

        // 5. Display Final Hash Output
        $display("[%0t] Compression Done. Final Hash Output (H0' to H7'):", $time);
        for (integer i = 0; i < 8; i = i + 1) begin
            $display("  H%0d' = 0x%h", i, H_final_out_dut[i]);
        end

        // 6. Finish Simulation
        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

endmodule

// Include necessary function modules (ch_func, maj_func, etc.) and adder_32bit
// `include "adder_32bit.v"
// `include "ch_func.v"
// `include "maj_func.v"
// `include "sigma0_comp_func.v"
// `include "sigma1_comp_func.v"
// `include "message_compression_folded.v" // Include the DUT itself if running separately