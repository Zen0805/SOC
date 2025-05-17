module message_compression (
    input wire          clk,
    input wire          rst_n,
    input wire          start,
    input wire [31:0]   Wt_in,
    output wire [255:0] H_final_out,
    output reg          busy,
    output reg          done,
    output reg          STN // Start new, tín hiệu này gửi qua sche qua ctrl là trung gian, báo hiệu bắt đầu tính toán 1 word mới của scheduler
                             // Bật lên ở STEP3, tắt ở STEP4,5,6,7  tuỳ duyên 
);

    localparam S_IDLE         = 4'd0;
    localparam S_INIT_LOAD    = 4'd1;
    //localparam S_ROUND_START  = 4'd2;
    localparam S_ROUND_STEP1  = 4'd3;
    localparam S_ROUND_STEP2  = 4'd4;
    localparam S_ROUND_STEP3  = 4'd5;
    localparam S_ROUND_STEP4  = 4'd6;
    localparam S_ROUND_STEP5  = 4'd7;
    localparam S_ROUND_STEP6  = 4'd8;
    localparam S_ROUND_STEP7  = 4'd9;
    localparam S_ROUND_UPDATE = 4'd10;
    localparam S_FINAL_ADD_ST = 4'd11;
    localparam S_FINAL_ADD    = 4'd12;
    localparam S_DONE         = 4'd13;

    //reg [31:0] Wt_saved; // Lưu Wt_in đđể dùng trong step4 mà không sợ bị ghi đè
    reg [3:0]  state, next_state;
    reg [31:0] reg_a, reg_b, reg_c, reg_d, reg_e, reg_f, reg_g, reg_h;
    reg [31:0] H_reg [7:0];
    reg [5:0]  round_counter;
    reg [3:0]  step_counter;
    reg [31:0] h_temp;
    reg [31:0] T1_reg;
    reg [31:0] d_new_reg;
    reg [31:0] a_new_calc;

    wire [31:0] Kt;
    wire [31:0] ch_out;
    wire [31:0] maj_out;
    wire [31:0] sigma0_out;
    wire [31:0] sigma1_out;
    wire [31:0] adder_in_a;
    wire [31:0] adder_in_b;
    wire [31:0] adder_sum_out;

    ch_func u_ch (.x(reg_e), .y(reg_f), .z(reg_g), .out(ch_out));
    maj_func u_maj (.x(reg_a), .y(reg_b), .z(reg_c), .out(maj_out));
    sigma0_func_compression u_sigma0 (.x(reg_a), .out(sigma0_out));
    sigma1_func_compression u_sigma1 (.x(reg_e), .out(sigma1_out));
    adder_32bit u_adder (.a(adder_in_a), .b(adder_in_b), .sum(adder_sum_out));

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
            a_new_calc <= 32'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            state <= next_state;
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
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

                S_INIT_LOAD: begin
                    reg_a <= H_reg[0]; reg_b <= H_reg[1]; reg_c <= H_reg[2]; reg_d <= H_reg[3];
                    reg_e <= H_reg[4]; reg_f <= H_reg[5]; reg_g <= H_reg[6]; reg_h <= H_reg[7];
                    round_counter <= 6'd0;
                end 

                // S_ROUND_START: begin
                //     // No updates
                // end

                S_ROUND_STEP1: h_temp <= adder_sum_out;
                S_ROUND_STEP2: h_temp <= adder_sum_out;
                S_ROUND_STEP3: begin
                    h_temp <= adder_sum_out;
                    STN <= 1'b1; // Bật STN lên để báo scheduler bắt đầu tính toán
                end
                S_ROUND_STEP4: T1_reg <= adder_sum_out;
                S_ROUND_STEP5: d_new_reg <= adder_sum_out;
                S_ROUND_STEP6: h_temp <= adder_sum_out;
                S_ROUND_STEP7: begin
                    a_new_calc <= adder_sum_out;
                    STN <= 1'b0; // Tắt STN trước khi bật lại ở step3
                end
                S_ROUND_UPDATE: begin
                    reg_a <= a_new_calc; reg_b <= reg_a; reg_c <= reg_b; reg_d <= reg_c;
                    reg_e <= d_new_reg; reg_f <= reg_e; reg_g <= reg_f; reg_h <= reg_g;
                    if (round_counter < 6'd63) begin
                        round_counter <= round_counter + 1;
                    end
                end

                S_FINAL_ADD_ST: step_counter <= 4'd0;

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

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: if (start) next_state = S_INIT_LOAD;
            S_INIT_LOAD: next_state = S_ROUND_STEP1;
            //S_ROUND_START: next_state = S_ROUND_STEP1;
            S_ROUND_STEP1: next_state = S_ROUND_STEP2;
            S_ROUND_STEP2: next_state = S_ROUND_STEP3;
            S_ROUND_STEP3: next_state = S_ROUND_STEP4;
            S_ROUND_STEP4: next_state = S_ROUND_STEP5;
            S_ROUND_STEP5: next_state = S_ROUND_STEP6;
            S_ROUND_STEP6: next_state = S_ROUND_STEP7;
            S_ROUND_STEP7: next_state = S_ROUND_UPDATE;
            S_ROUND_UPDATE: if (round_counter == 6'd63) next_state = S_FINAL_ADD_ST;
                            else next_state = S_ROUND_STEP1;
            S_FINAL_ADD_ST: next_state = S_FINAL_ADD;
            S_FINAL_ADD: if (step_counter == 4'd7) next_state = S_DONE;
            S_DONE: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    assign H_final_out = {H_reg[0], H_reg[1], H_reg[2], H_reg[3], H_reg[4], H_reg[5], H_reg[6], H_reg[7]};

endmodule
