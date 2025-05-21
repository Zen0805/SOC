module IP_wrapper (
    // Avalon Bus Signals
    input wire         iClk,               // Xung clock
    input wire         iReset_n,           // Reset active-low
    input wire         iChipselect_n,      // Tín hiệu chọn IP (active-low)
    input wire         iWrite_n,           // Tín hiệu ghi (active-low)
    input wire         iRead_n,            // Tín hiệu đọc (active-low)
    input wire [4:0]   iAddress,           // Địa chỉ 5-bit
    input wire [31:0]  iData,              // Dữ liệu từ Nios II
    output reg [31:0]  oData                // Dữ liệu trả về Nios II
	 
	

	 
	 
	 
    // ____________________________Debug_________________________________
	 //output wire reset_n_new_input_comp
	 //output wire           state_ctrl,
    //output reg            START,              // Khởi động module SHA-256S
    //output reg     [31:0] DATA_IN,            // Dữ liệu gửi đến SHA-256 top
	 //output wire 	[3:0]	 load_counter,
    //output wire           DATA_VALID         // Tín hiệu báo dữ liệu hợp lệ
	 //______________________________Debug_________________________________
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 //output wire 	[255:0]	  hash_result_256
	 
    //output wire         DONE               // Tín hiệu hoàn tất từ SHA-256
    //input wire [255:0] output_sha256top    // Kết quả hash 256-bit
	 //______________________________Debug_________________________________
);

    // Thanh ghi nội bộ
    reg [31:0] control_reg;           // Thanh ghi điều khiển: BIT0 START, 
    reg [511:0] data_in_reg;           // Thanh ghi dữ liệu đầu vào
    reg [31:0] status_reg;            // Thanh ghi trạng thái BITO DONE
	 
    wire [255:0] hash_result_256;     // Thanh ghi 256 bit cho kết quả hash
	 
	 
	 reg         start_calc;          // Tín hiệu bắt đầu tính toán
	 reg 			 START;						
	 reg [31:0]  DATA_IN;              // Dữ liệu gửi đến SHA-256 top
	 wire [3:0]  load_counter;     // Đếm số từ đã load (0-15)
	 wire        DATA_VALID;           // Tín hiệu báo dữ liệu hợp lệ
   
	 
	 wire DONE;
	 
	 wire reset_n_new_input_comp;
	 
	 

    // Gán tín hiệu 
    assign DATA_VALID = start_calc;
	 assign reset_n_new_input_comp = control_reg[4];
	 //load_counter <= load_counter_ctrl;


    // Logic ghi
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            control_reg <= 32'b0;
            data_in_reg <= 32'b0;
            status_reg <= 32'b0;
            //hash_result_256 <= 256'b0;
            START <= 1'b0;
            start_calc <= 1'b0;
				//test <= 1'b0;
        end else begin
            if (!iChipselect_n && !iWrite_n) begin
                case (iAddress)
                    5'h00: begin // Thanh ghi điều khiển
								//01 : Tín hiệu bắt đầu 1 input mới
								//11 : Tín hiệu bắt đầu 1 block mới trong 1 input
                        control_reg <= iData;
                        //START <= iData[0]; // Bit 0: start ___Debug__
                        
                       
                    end
                    5'h01: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[511:480] <= iData;
								//START <= 1'b0;		//LƯU Ý CHỖ NÀY LÀ TẮT MỖI START THÔI CHỨ TRONG THANH GHI CONTROL REG THÌ GIÁ TRỊ VẪN LÀ 1
                    end

                    5'h02: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[479:448] <= iData;
                    end

                    5'h03: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[447:416] <= iData;
                    end

                    5'h04: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[415:384] <= iData;
                    end

                    5'h05: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[383:352] <= iData;
                    end

                    5'h06: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[351:320] <= iData;
                    end

                    5'h07: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[319:288] <= iData;
                    end

                    5'h08: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[287:256] <= iData;
                    end

                    5'h09: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[255:224] <= iData;
                    end

                    5'h0A: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[223:192] <= iData;
                    end

                    5'h0B: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[191:160] <= iData;
                    end

                    5'h0C: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[159:128] <= iData;
                    end

                    5'h0D: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[127:96] <= iData;
                    end

                    5'h0E: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[95:64] <= iData;
                    end

                    5'h0F: begin // Thanh ghi dữ liệu đầu vào
                        if(control_reg[0]) data_in_reg[63:32] <= iData;
                    end

                    5'h10: begin // Thanh ghi dữ liệu đầu vào
								if(control_reg[0]) begin
									data_in_reg[31:0] <= iData;
									start_calc <= 1'b1; // Bắt đầu tính toán khi ghi xong dữ liệu4
								end
                    end

                    default: begin
                        // Không làm gì cả
                    end

                endcase
            end
				
				if(load_counter == 15)begin //Tắt sau 1 cc khi load xong data
						
						start_calc <= 1'b0;
					
				end

            // Cập nhật trạng thái và kết quả khi hoàn tất
            if (DONE) begin
                status_reg[0] <= 1'b1; // Đặt bit done
                //hash_result_256 <= output_sha256top; // Lưu toàn bộ 256 bit
            end else if (control_reg[0] == 1'b0) begin
                status_reg[0] <= 1'b0; // Reset bit done khi START thấp
            end
        end
    end

    always @(posedge iClk or negedge iReset_n) begin
		  if(iClk) begin
            if(DATA_VALID) begin //PHải là datavalid vì nếu là start_calc thì lỗi cycle chuyển dữ liệu
                
                case (load_counter)
                    4'b0000: begin
                        DATA_IN <= data_in_reg[511:480];
                    end
                    4'b0001: begin
                        DATA_IN <= data_in_reg[479:448];
                    end
                    4'b0010: begin
                        DATA_IN <= data_in_reg[447:416];
                    end
                    4'b0011: begin
                        DATA_IN <= data_in_reg[415:384];
                    end
                    4'b0100: begin
                        DATA_IN <= data_in_reg[383:352];
                    end
                    4'b0101: begin
                        DATA_IN <= data_in_reg[351:320];
                    end
                    4'b0110: begin
                        DATA_IN <= data_in_reg[319:288];
                    end
                    4'b0111: begin
                        DATA_IN <= data_in_reg[287:256];
                    end
                    4'b1000: begin
                        DATA_IN <= data_in_reg[255:224];
                    end
                    4'b1001: begin
                        DATA_IN <= data_in_reg[223:192];
                    end
                    4'b1010: begin
                        DATA_IN <= data_in_reg[191:160];
                    end
                    4'b1011: begin
                        DATA_IN <= data_in_reg[159:128];
                    end
                    4'b1100: begin
                        DATA_IN <= data_in_reg[127:96];
                    end
                    4'b1101: begin
                        DATA_IN <= data_in_reg[95:64];
                    end
                    4'b1110: begin
                        DATA_IN <= data_in_reg[63:32];
                    end
                    4'b1111: begin
                        DATA_IN <= data_in_reg[31:0];
                        //start_calc <= 1'b0; // Tắt tín hiệu start_calc = tắt Data Valid
                    end
                    default: begin
                        // Không làm gì cả
                    end
                endcase
					 //load_counter <= load_counter + 1; // Tăng bộ đếm load
					 
            end
			end
    end

    // Logic đọc
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            oData <= 32'b0;
        end else if (!iChipselect_n && !iRead_n) begin
            
            case (iAddress)
                5'h00: oData <= control_reg;          // Đọc thanh ghi điều khiển
                5'h1A: oData <= status_reg;           // Đọc trạng thái



                5'h12: oData <= hash_result_256[255:224]; // Đọc kết quả hash 256 bit
                5'h13: oData <= hash_result_256[223:192]; // Đọc kết quả hash 256 bit
                5'h14: oData <= hash_result_256[191:160]; // Đọc kết quả hash 256 bit
                5'h15: oData <= hash_result_256[159:128]; // Đọc kết quả hash 256 bit
                5'h16: oData <= hash_result_256[127:96];  // Đọc kết quả hash 256 bit
                5'h17: oData <= hash_result_256[95:64];   // Đọc kết quả hash 256 bit
                5'h18: oData <= hash_result_256[63:32];   // Đọc kết quả hash 256 bit
                5'h19: oData <= hash_result_256[31:0];    // Đọc kết quả hash 256 bit

                default: oData <= 32'b0;
            endcase
        end
    end

    // Kết nối module SHA-256
    sha256_optimizePowerAreaVerilog sha256_core (
        .CLK(iClk),
        .RESET_N(iReset_n),
        .START(start_calc),
        .DATA_VALID(DATA_VALID),
        .DATA_IN(DATA_IN),
        .done(DONE),
        .output_sha256top(hash_result_256),
		  .load_counter_ctrl(load_counter),
		  .state_ctrl(state_ctrl),
		  .reset_n_new_input_comp_from_ip_wrapper(reset_n_new_input_comp)
    );

endmodule