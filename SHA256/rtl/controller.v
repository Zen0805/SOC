module controller (
    input clk,                  // Clock hệ thống
    input reset_n,              // Reset active-low
    input start,                // Tín hiệu start từ NIOS II
    input [31:0] wrapper_data,  // Dữ liệu từ IP wrapper
    input wrapper_data_valid,   // Tín hiệu báo dữ liệu từ wrapper hợp lệ
    output reg wrapper_data_request, // Tín hiệu yêu cầu dữ liệu từ wrapper
    // Tín hiệu đến module sche
    output wire [31:0] message_word_in,  // Dữ liệu đầu vào cho sche
    output wire [3:0] message_word_addr, // Địa chỉ từ 0-15
    output reg write_enable_in,          // Tín hiệu ghi cho sche
    output reg start_to_sche,            // Tín hiệu start cho sche
    output wire [5:0] round_t,           // Round từ 0-63
    output wire STN_to_sche,             // STN từ comp qua sche
    input [31:0] Wt_from_sche,           // Nhận Wt từ sche
    // Tín hiệu đến module comp
    output reg [31:0] Wt_to_comp,        // Truyền Wt sang comp
    output reg start_to_comp,            // Tín hiệu start cho comp
    input STN_from_comp,                 // Nhận STN từ comp
    input done_from_comp                 // Tín hiệu hoàn thành từ comp
);

    // Định nghĩa các trạng thái
    localparam IDLE = 1'b0;
    localparam PROCESSING = 1'b1;

    reg state;                  // Trạng thái hiện tại
    reg next_state;             // Trạng thái tiếp theo
    reg [3:0] load_counter;     // Đếm số từ đã load (0-15)
    reg [5:0] round_counter;    // Đếm round (0-63)
    reg loading_active;         // Cờ báo hiệu quá trình load data đang diễn ra

    // Khối always duy nhất để gán next_state (logic tổ hợp)
    always @(*) begin
        case (state)
            IDLE: next_state = start ? PROCESSING : IDLE; // Chuyển sang PROCESSING khi nhận start
            PROCESSING: next_state = (round_counter == 64 && done_from_comp) ? IDLE : PROCESSING; // Quay về IDLE khi hoàn thành
            default: next_state = IDLE;
        endcase
    end

	 always @(posedge STN_from_comp or negedge reset_n) begin
        if (!reset_n) begin
            round_counter <= 6'b0; // Reset round_counter khi nhận STN
        end else begin
				case (state)
					IDLE: begin
						if(start) begin
							round_counter <= 6'b0;
						end
					end
				endcase
			
            if (round_counter < 64) begin
                round_counter <= round_counter + 1; // Tăng round_counter khi nhận STN
            end
        end
    end
	 
    // Khối always để cập nhật trạng thái và các tín hiệu khác (logic tuần tự)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            load_counter <= 4'b0;
            wrapper_data_request <= 1'b0;
            write_enable_in <= 1'b0;
            start_to_sche <= 1'b0;
            start_to_comp <= 1'b0;
            Wt_to_comp <= 32'b0;
            loading_active <= 1'b0;
        end else begin
            state <= next_state; // Cập nhật trạng thái từ next_state

            case (state)
                IDLE: begin
                    if (start) begin
                        wrapper_data_request <= 1'b1; // Yêu cầu dữ liệu từ IP wrapper
                        load_counter <= 4'b0;
                        start_to_sche <= 1'b1;      // Bật tín hiệu start cho sche
                        start_to_comp <= 1'b1;      // Bật tín hiệu start cho comp
                        loading_active <= 1'b1;     // Bắt đầu quá trình load data
                    end
                end
                PROCESSING: begin
                    // Quản lý việc load data
                    if (loading_active && wrapper_data_valid && load_counter < 16) begin
                        load_counter <= load_counter + 1;   // Tăng bộ đếm load
                        write_enable_in <= 1'b1;            // Bật tín hiệu ghi
                        if (load_counter == 15) begin
                            loading_active <= 1'b0;     // Kết thúc load data
                            wrapper_data_request <= 1'b0; // Tắt yêu cầu dữ liệu
                            write_enable_in <= 1'b0;    // Tắt tín hiệu ghi
                        end
                    end

                    // Quản lý quá trình tính toán
                    if (round_counter < 64) begin
                        Wt_to_comp <= Wt_from_sche; // Truyền Wt từ sche sang comp (bao gồm cả round_t < 16)
              
                    end else if (done_from_comp) begin
                        start_to_sche <= 1'b0;      // Tắt start cho sche
                        start_to_comp <= 1'b0;      // Tắt start cho comp
                    end
                end
            endcase
        end
    end

    // Logic tổ hợp cho các tín hiệu wire
    assign STN_to_sche = STN_from_comp;              // Truyền STN từ comp đến sche trực tiếp
    assign round_t = round_counter;                  // Gán round_t từ round_counter
    assign message_word_in = (loading_active && wrapper_data_valid) ? wrapper_data : 32'b0; // Gán dữ liệu từ wrapper khi load
    assign message_word_addr = (loading_active) ? load_counter : 4'b0; // Gán địa chỉ từ load_counter khi load

endmodule