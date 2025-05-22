module IP_wrapper (
    // Avalon Bus
    input wire         iClk,               
    input wire         iReset_n,           
    input wire         iChipselect_n,      
    input wire         iWrite_n,          
    input wire         iRead_n,           
    input wire [4:0]   iAddress,          
    input wire [31:0]  iData,              
    output reg [31:0]  oData               
	 
	
);

    // Thanh ghi nội bộ
    reg [31:0] control_reg;           
    reg [511:0] data_in_reg;           
    reg [31:0] status_reg;            
	 
    wire [255:0] hash_result_256;     
	 
	 
	 reg         start_calc;           // Tín hiệu bắt đầu tính toán cho top module						
	 reg [31:0]  DATA_IN;              // Data gửi đến top module
	 wire [3:0]  load_counter;         
	 wire        DATA_VALID;           
   
	 
	 wire DONE;
	 
	 wire reset_n_new_input_comp;
	 
	 

    // Gán tín hiệu 
    assign DATA_VALID = start_calc;
	 assign reset_n_new_input_comp = control_reg[4];


    // Logic ghi
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            control_reg <= 32'b0;
            data_in_reg <= 32'b0;
            status_reg <= 32'b0;
            start_calc <= 1'b0;
        end else begin
            if (!iChipselect_n && !iWrite_n) begin
                case (iAddress)
                    5'h00: begin // Thanh ghi control
								//01 : Tín hiệu bắt đầu 1 input mới
								//11 : Tín hiệu bắt đầu 1 block mới trong 1 input
                        control_reg <= iData;
                        
                    end
                    5'h01: begin 
                        if(control_reg[0]) data_in_reg[511:480] <= iData;
                    end

                    5'h02: begin 
                        if(control_reg[0]) data_in_reg[479:448] <= iData;
                    end

                    5'h03: begin 
                        if(control_reg[0]) data_in_reg[447:416] <= iData;
                    end

                    5'h04: begin 
                        if(control_reg[0]) data_in_reg[415:384] <= iData;
                    end

                    5'h05: begin 
                        if(control_reg[0]) data_in_reg[383:352] <= iData;
                    end

                    5'h06: begin
                        if(control_reg[0]) data_in_reg[351:320] <= iData;
                    end

                    5'h07: begin
                        if(control_reg[0]) data_in_reg[319:288] <= iData;
                    end

                    5'h08: begin
                        if(control_reg[0]) data_in_reg[287:256] <= iData;
                    end

                    5'h09: begin 
                        if(control_reg[0]) data_in_reg[255:224] <= iData;
                    end

                    5'h0A: begin
                        if(control_reg[0]) data_in_reg[223:192] <= iData;
                    end

                    5'h0B: begin
                        if(control_reg[0]) data_in_reg[191:160] <= iData;
                    end

                    5'h0C: begin
                        if(control_reg[0]) data_in_reg[159:128] <= iData;
                    end

                    5'h0D: begin
                        if(control_reg[0]) data_in_reg[127:96] <= iData;
                    end

                    5'h0E: begin 
                        if(control_reg[0]) data_in_reg[95:64] <= iData;
                    end

                    5'h0F: begin 
                        if(control_reg[0]) data_in_reg[63:32] <= iData;
                    end

                    5'h10: begin 
								if(control_reg[0]) begin
									data_in_reg[31:0] <= iData;
									start_calc <= 1'b1; 
								end
                    end

                    default: begin
                        
                    end

                endcase
            end
				
				if(load_counter == 15)begin 
						
						start_calc <= 1'b0;
					
				end

            // Khi hoàn tất
            if (DONE) begin
                status_reg[0] <= 1'b1; //Bit done
            end else if (control_reg[0] == 1'b0) begin
                status_reg[0] <= 1'b0; // Reset done
            end
        end
    end

    always @(posedge iClk or negedge iReset_n) begin
		  if(iClk) begin
            if(DATA_VALID) begin //DATA_VALID WIRE > start_calc reg
                
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
                    end
                    default: begin
                       
                    end
                endcase
            end
			end
    end

    //Logic đọc
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            oData <= 32'b0;
        end else if (!iChipselect_n && !iRead_n) begin
            
            case (iAddress)
                5'h00: oData <= control_reg;          
                5'h1A: oData <= status_reg;          



                5'h12: oData <= hash_result_256[255:224]; 
                5'h13: oData <= hash_result_256[223:192]; 
                5'h14: oData <= hash_result_256[191:160]; 
                5'h15: oData <= hash_result_256[159:128]; 
                5'h16: oData <= hash_result_256[127:96];  
                5'h17: oData <= hash_result_256[95:64];   
                5'h18: oData <= hash_result_256[63:32];   
                5'h19: oData <= hash_result_256[31:0];    

                default: oData <= 32'b0;
            endcase
        end
    end

    // topmodule SHA-256
    sha256_optimizePowerAreaVerilog sha256_core (
        .CLK(iClk),
        .RESET_N(iReset_n),
        .START(start_calc),
        .DATA_VALID(DATA_VALID),
        .DATA_IN(DATA_IN),
        .done(DONE),
        .output_sha256top(hash_result_256),
		  .load_counter_ctrl(load_counter),
		  .reset_n_new_input_comp_from_ip_wrapper(reset_n_new_input_comp)
    );

endmodule