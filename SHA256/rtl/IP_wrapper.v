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
    //output reg         START,              // Khởi động module SHA-256S
    //output wire [31:0] DATA_IN,            // Dữ liệu gửi đến SHA-256 top
    //output wire        DATA_VALID,         // Tín hiệu báo dữ liệu hợp lệ
	 
    //output wire         DONE               // Tín hiệu hoàn tất từ SHA-256
    //input wire [255:0] output_sha256top    // Kết quả hash 256-bit
	 //______________________________Debug_________________________________
);

    // Thanh ghi nội bộ
    reg [31:0] control_reg;           // Thanh ghi điều khiển
    reg [31:0] data_in_reg;           // Thanh ghi dữ liệu đầu vào
    reg [31:0] status_reg;            // Thanh ghi trạng thái
	 
    wire [255:0] hash_result_256;     // Thanh ghi 256 bit cho kết quả hash
	 
	 reg START;								
	 wire [31:0] DATA_IN;              // Dữ liệu gửi đến SHA-256 top
    wire        DATA_VALID;           // Tín hiệu báo dữ liệu hợp lệ
	 
	 wire DONE;

    // Gán tín hiệu 
    assign DATA_IN = data_in_reg;
    assign DATA_VALID = (iAddress == 5'h01) && (!iWrite_n) && (!iChipselect_n); 


    // Logic ghi
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            control_reg <= 32'b0;
            data_in_reg <= 32'b0;
            status_reg <= 32'b0;
            //hash_result_256 <= 256'b0;
            START <= 1'b0;
        end else begin
            if (!iChipselect_n && !iWrite_n) begin
                case (iAddress)
                    5'h00: begin // Thanh ghi điều khiển
                        control_reg <= iData;
                        START <= iData[0]; // Bit 0: start
                    end
                    5'h01: begin // Thanh ghi dữ liệu đầu vào
                        data_in_reg <= iData;
								START <= 1'b0;		//LƯU Ý CHỖ NÀY LÀ TẮT MỖI START THÔI CHỨ TRONG THANH GHI CONTROL REG THÌ GIÁ TRỊ VẪN LÀ 1
                    end
                endcase
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

    // Logic đọc
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            oData <= 32'b0;
        end else if (!iChipselect_n && !iRead_n) begin
            case (iAddress)
                5'h00: oData <= control_reg;          // Đọc thanh ghi điều khiển
                5'h02: oData <= status_reg;           // Đọc trạng thái
                5'h03: oData <= hash_result_256[255:224];   // 32 bit đầu tiên
                5'h04: oData <= hash_result_256[223:192];  // 32 bit tiếp theo
                5'h05: oData <= hash_result_256[191:160];
                5'h06: oData <= hash_result_256[159:128];
                5'h07: oData <= hash_result_256[127:96];
                5'h08: oData <= hash_result_256[95:64];
                5'h09: oData <= hash_result_256[63:32];
                5'h0A: oData <= hash_result_256[31:0]; // 32 bit cuối cùng
                default: oData <= 32'b0;
            endcase
        end
    end

    // Kết nối module SHA-256
    sha256_optimizePowerArea sha256_core (
        .CLK(iClk),
        .RESET_N(iReset_n),
        .START(START),
        .DATA_VALID(DATA_VALID),
        .DATA_IN(DATA_IN),
        .done(DONE),
        .output_sha256top(hash_result_256),
    );

endmodule