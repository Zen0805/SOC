module message_scheduler (
    input wire          clk,
    input wire          reset_n,           
    input wire          STN,               
    input wire  [5:0]   round_t,           
    input wire  [31:0]  message_word_in,   
    input wire  [3:0]   message_word_addr, 
    input wire          write_enable_in, 
	 input wire reset_new_block, 
    output wire [31:0]  Wt_out          
	 
	 
	 
	 //________________________________DEBUG___________________________________//
	 //output wire 			StnSaved_out,
	 //output wire [1:0] 	CALC_CYCLE_OUT,     // 0: s1, 1: s2, 2: s3, 3: s4
    //output wire 			CALC_ACTIVE_OUT, // Đánh dấu đang tính toán 4 chu kỳ
    //output wire [31:0] 	PREV_WT_OUT, 
	 //output wire [3:0] 	WA_OUT,
	 //output wire [31:0]	ADD_IN_A_OUT,       // Đầu vào A của bộ cộng
    //output wire [31:0] 	ADD_IN_B_OUT,       // Đầu vào B của bộ cộng
    //output wire [31:0] 	ADD_SUM_OUT,
	 //
	 //
	 //
	 //output wire [3:0] 	addr_t_minus_16_out,
    //output wire [3:0] 	addr_t_minus_15_out,
    //output wire [3:0] 	addr_t_minus_7_out,
    //output wire [3:0] 	addr_t_minus_2_out,
	 //
	 //output wire [31:0] 	mem_out_t_minus_16_out ,
    //output wire [31:0]	mem_out_t_minus_15_out ,
    //output wire [31:0]	mem_out_t_minus_7_out  ,
    //output wire [31:0]	mem_out_t_minus_2_out  ,
	 //________________________________DEBUG___________________________________//
	 
	 
	 
	 
);


    reg STNSaved;                   // Biến bool để kích hoạt tính toán 1 WORD, giữ cho đến khi tính xong 

    // --- Internal Signals ---
    reg [31:0] W_memory [15:0];     // Bộ nhớ lưu 16 từ W[t-16] đến W[t-1]
    reg [31:0] reg_w;               // Lưu kết quả cộng trung gian và W[t] cuối cùng
    reg [1:0] calc_cycle;           // 0: s1, 1: s2, 2: s3, 3: s4
    reg calculation_active;         // Đánh dấu đang tính toán 4 chu kỳ
    reg [31:0] prev_wt;             // Lưu W[t] của vòng trước để ghi ở vòng sau

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
    assign addr_t_minus_16 = round_t[3:0];              // W[t-16] = t mod 16
    assign addr_t_minus_15 = (round_t - 6'd15) & 4'hF;  // (t-15) mod 16
    assign addr_t_minus_7  = (round_t - 6'd7) & 4'hF;   // (t-7) mod 16
    assign addr_t_minus_2  = (round_t - 6'd2) & 4'hF;   // (t-2) mod 16
    assign write_addr      = addr_t_minus_16;           // Ghi đè lên W[t-16]

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
    assign adder_in_a = (calculation_active && calc_cycle == 2'b00) ? mem_out_t_minus_16 :
                        (calculation_active && (calc_cycle == 2'b01 || calc_cycle == 2'b10)) ? reg_w :
                        32'b0;

    assign adder_in_b = (calculation_active && calc_cycle == 2'b00) ? sigma0_result :
                        (calculation_active && calc_cycle == 2'b01) ? mem_out_t_minus_7 :
                        (calculation_active && calc_cycle == 2'b10) ? sigma1_result :
                        32'b0;

	 
    always @(posedge STN or posedge clk) begin
        if(STN) begin
            STNSaved <= 1'b1;
        end else begin
            if(calc_cycle == 2'b11) begin
                STNSaved <= 1'b0; // Tắt STNSaved sau khi tính xong
            end
        end
    end


    // --- Logic điều khiển và cập nhật trạng thái (Sequential) ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            calc_cycle <= 2'b00;
            reg_w <= 32'b0;
            calculation_active <= 1'b0;
            prev_wt <= 32'b0;
				
				//Reset 16 thanh ghi
            W_memory[0] <= 32'b0;
            W_memory[1] <= 32'b0;          
            W_memory[2] <= 32'b0;
            W_memory[3] <= 32'b0;
            W_memory[4] <= 32'b0;
            W_memory[5] <= 32'b0;
            W_memory[6] <= 32'b0;
            W_memory[7] <= 32'b0;
            W_memory[8] <= 32'b0;
            W_memory[9] <= 32'b0;
            W_memory[10] <= 32'b0;
            W_memory[11] <= 32'b0;
            W_memory[12] <= 32'b0;
            W_memory[13] <= 32'b0;
            W_memory[14] <= 32'b0;
            W_memory[15] <= 32'b0;
	
        end else begin
		  
					 if(!reset_new_block) begin
						   W_memory[0] <= 32'b0;
							W_memory[1] <= 32'b0;          
							W_memory[2] <= 32'b0;
							W_memory[3] <= 32'b0;
							W_memory[4] <= 32'b0;
							W_memory[5] <= 32'b0;
							W_memory[6] <= 32'b0;
							W_memory[7] <= 32'b0;
							W_memory[8] <= 32'b0;
							W_memory[9] <= 32'b0;
							W_memory[10] <= 32'b0;
							W_memory[11] <= 32'b0;
							W_memory[12] <= 32'b0;
							W_memory[13] <= 32'b0;
							W_memory[14] <= 32'b0;
							W_memory[15] <= 32'b0;
					 end
            
                // --- Ghi dữ liệu đầu vào (M[i]) vào memory ---
                if (write_enable_in) begin
                    W_memory[message_word_addr] <= message_word_in;
                end

                // --- Tính toán W[t] cho t >= 16 ---
                if (round_t >= 6'd16) begin
                    if(STNSaved) begin
                        if (!calculation_active) begin // Bắt đầu tính toán cho round mới
                            calculation_active <= 1'b1;
                            calc_cycle <= 2'b00;
                            // Ghi W[t-1] từ vòng trước vào bộ nhớ ở cycle 0 của vòng mới
                            
                        end else begin // Đang trong quá trình tính toán
                            if (calc_cycle == 2'b00 || calc_cycle == 2'b01 || calc_cycle == 2'b10) begin
                                reg_w <= adder_sum_out;
                            end
                            case (calc_cycle)
                                2'b00: begin
                                    calc_cycle <= 2'b01;
                                end
                                2'b01: begin
												if (round_t > 6'd16) begin
													if(write_addr == 0) begin
														W_memory[15] <= prev_wt;
													end else begin
														W_memory[write_addr - 1] <= prev_wt;
													end
													
												end
												calc_cycle <= 2'b10;
										  end
                                2'b10: begin
                                    calc_cycle <= 2'b11;
                                    prev_wt <= adder_sum_out; // Lưu W[t] cho lần ghi tiếp theo
                                end
                                2'b11: begin
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
                end else begin // round_t < 16
                    calculation_active <= 1'b0;
                    calc_cycle <= 2'b00;
                end
            
        end
    end

 
    assign Wt_out = (round_t < 6'd16) ? W_memory[round_t] : reg_w;
	 
	 
	 
	 
	 //________________________________DEBUG___________________________________//
	 
	 //assign StnSaved_out = STNSaved;
	 //assign CALC_CYCLE_OUT = calc_cycle;           // 0: s1, 1: s2, 2: s3, 3: s4
    //assign CALC_ACTIVE_OUT = calculation_active;         // Đánh dấu đang tính toán 4 chu kỳ
    //assign PREV_WT_OUT = prev_wt; 
	 //assign WA_OUT = write_addr;
	 //assign ADD_IN_A_OUT = adder_in_a;         // Đầu vào A của bộ cộng
    //assign ADD_IN_B_OUT = adder_in_b;         // Đầu vào B của bộ cộng
    //assign ADD_SUM_OUT = adder_sum_out;
	 //
	 //
	 //assign addr_t_minus_16_out = addr_t_minus_16;
    //assign addr_t_minus_15_out = addr_t_minus_15;
    //assign addr_t_minus_7_out = addr_t_minus_7;
    //assign addr_t_minus_2_out = addr_t_minus_2;
	 //
	 //
	 //assign mem_out_t_minus_16_out = mem_out_t_minus_16;
	 //assign mem_out_t_minus_15_out = mem_out_t_minus_15;
	 //assign mem_out_t_minus_7_out  = mem_out_t_minus_7 ;
	 //assign mem_out_t_minus_2_out  = mem_out_t_minus_2 ;
	 
	 //________________________________DEBUG___________________________________//

endmodule


