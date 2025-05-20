module sha256_avalon (
    input wire         iClk,          // Xung nhá»‹p
    input wire         iReset_n,        // Reset (active-high)
    input wire         iChipSelect_n,   // TÃ­n hiá»‡u chá»n slave
    input wire         iWrite_n,        // YÃªu cáº§u ghi
    input wire         iRead_n,         // YÃªu cáº§u Ä‘á»c
    input wire [4:0]   iAddress,      // Äá»‹a chá»‰ (3 bit, Ä‘á»§ cho 8 thanh ghi)
    input wire [31:0]  iData,         // Dá»¯ liá»‡u ghi tá»« master (64 bit)
    output reg [31:0]  oData         // Dá»¯ liá»‡u Ä‘á»c tráº£ vá» master (64 bit)
);

    // Internal signals
    wire        start_block;          
    wire [511:0] data_in_word;         
    wire        data_in_valid;        
    wire [255:0] hash_out;            
    wire        hash_valid;           
    wire        busy;                 // Driven by sha256_top
	wire 		 comp_done;
	wire reset_n;

    // Internal registers
    reg [511:0]  data_in_reg;          
    reg         start_reg;            
    reg         valid_in_reg;
	 reg rst_n;

    // Avalon-MM control logic
    always @(posedge iClk or negedge iReset_n) begin
        if (~iReset_n) begin
            data_in_reg <= 64'd0;
            start_reg <= 1'b0;
            valid_in_reg <= 1'b0;
            oData <= 64'd0;
        end else begin
            // Default assignments
            start_reg <= 1'b0;
				valid_in_reg <= 1'b0;
				rst_n <= 1'b1;
            // Write handling
            if (~iChipSelect_n && ~iWrite_n) begin
                case (iAddress)
                    5'b00000: begin // Control register
                        start_reg <= iData[0];    // Bit 0: Start
                    end
                    5'b00001: begin // Input data register
                        data_in_reg[511:480] <= iData;
                    end
						  5'b00010: begin // Input data register
                        data_in_reg [479:448] <= iData;
						  end 
						  5'b00011: begin // Input data register
                        data_in_reg [447:416] <= iData;
                    end
						  5'b00100:begin // Input data register
                        data_in_reg[415:384]<= iData;
                    end
						  5'b00101:begin // Input data register
                        data_in_reg[383:352] <= iData;
                    end
						  5'b00110:begin // Input data register
                        data_in_reg[351:320] <= iData;
                    end
						  5'b00111:begin // Input data register
                        data_in_reg[319:288] <= iData;
                    end
						  5'b01000:begin // Input data register
                        data_in_reg[287:256] <= iData;
                    end
						  5'b01001:begin // Input data register
                        data_in_reg[255:224] <= iData;
                    end
						  5'b01010:begin // Input data register
                        data_in_reg[223:192] <= iData;
                    end
						  5'b01011:begin // Input data register
                        data_in_reg[191:160] <= iData;
                    end
						  5'b01100:begin // Input data register
                        data_in_reg[159:128] <= iData;
                    end
						  5'b01101:begin // Input data register
                        data_in_reg[127:96] <= iData;
                    end
						  5'b01110:begin // Input data register
                        data_in_reg[95:64] <= iData;
                    end
						  5'b01111:begin // Input data register
                        data_in_reg[63:32] <= iData;
                    end
						  5'b10000:begin // Input data register
                        data_in_reg[31:0] <= iData;
								valid_in_reg <= 1;
                    end
						  5'b10001:begin // Input data register
                        rst_n <= 1'b0;
                    end

                    default: begin
                       
                    end
                endcase
            end

            // Read handling
            if (~iChipSelect_n && ~iRead_n) begin
                case (iAddress)
                    5'b00000: begin // Status register
                        oData <= {29'd0, busy,comp_done}; 
                    end
                    5'b00001: oData <= hash_out[255:224];   
                    5'b00010: oData <= hash_out[223:192]; 
                    5'b00011: oData <= hash_out[191:160];
                    5'b00100: oData <= hash_out[159:128];
						  5'b00101: oData <= hash_out[127:96];   
                    5'b00110: oData <= hash_out[95:64]; 
                    5'b00111: oData <= hash_out[63:32];
                    5'b01000: oData <= hash_out[31:0];
                    default: oData <= 32'd0;
                endcase
            end else begin
                oData <= 32'd0; // Default value for oData when not reading
            end

           
        end
    end

    // Signal assignments
    assign start_block = start_reg;
    assign data_in_word = data_in_reg;
    assign data_in_valid = valid_in_reg;
	 assign reset_n = rst_n & iReset_n;

    // Instantiate SHA-256 core
    sha256_top sha256_core (
        .clk(iClk),
        .rst_n(reset_n),              // Convert active-high to active-low
        .start_block(start_block),
        .block_in(data_in_word),
        .block_valid(data_in_valid),
        .busy(busy),
        .hash_out(hash_out),
		  .comp_done(comp_done)
    );

endmodule
