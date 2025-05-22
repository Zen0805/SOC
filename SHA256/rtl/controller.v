module controller (
    input clk,                  
    input reset_n,              
    input start,                
    input [31:0] wrapper_data,  
    input wrapper_data_valid,   
	 
    // Tín hiệu đến module sche
    output wire [31:0] message_word_in,  
    output wire [3:0] message_word_addr, 
    output reg write_enable_in,      
    output wire [5:0] round_t,           
    output wire STN_to_sche,             
    input [31:0] Wt_from_sche,           
	 output reg reset_n_sche_reg,
	 
    // Tín hiệu đến module comp
    output reg [31:0] Wt_to_comp,       
	 output wire start_to_comp,
	 output done,
	 output [255:0] hash_output,
	 
    input STN_from_comp,                 
    input done_from_comp,  
	 input [255:0]  hash_final_from_comp, 
	 output reg [3:0] load_counter,
	 
	 
	 //Reset thanh ghi comp
	 input wire iResetn_new_input_to_comp,
	 output wire oResetn_new_input_to_comp
);

    
    localparam IDLE = 1'b0;
    localparam PROCESSING = 1'b1;

	 reg state;
    reg next_state;             
    reg [5:0] round_counter;    
    reg loading_active;         
	 
    always @(*) begin
        case (state)
            IDLE: next_state = start ? PROCESSING : IDLE; 						// Chuyển sang PROCESSING khi nhận start
            PROCESSING: next_state = (done_from_comp) ? IDLE : PROCESSING; // Quay về IDLE khi done
            default: next_state = IDLE;
        endcase
    end

	 //Logic tăng round
	 always @(posedge STN_from_comp or negedge reset_n) begin
        if (!reset_n) begin
            round_counter <= 6'b0; // Reset round_counter khi nhận STN
        end else begin
		  
            if (round_counter < 63) begin 
                round_counter <= round_counter + 1; // Tăng round_counter khi nhận STN
            end
				
				if((round_counter == 63))begin
					round_counter <= 0;
					//reset 
				end
				
        end 
    end
	 
	 
	 //Logic điều khiển
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            load_counter <= 4'b0;
            write_enable_in <= 1'b0;
            Wt_to_comp <= 32'b0;
            loading_active <= 1'b0;
				
				reset_n_sche_reg <= 1'b1;
        end else begin
            state <= next_state; 

            case (state)
                IDLE: begin
						  
                    if (start) begin 
                        load_counter <= 4'b0;    
                        loading_active <= 1'b1;       
								write_enable_in <= 1'b1;      
								reset_n_sche_reg  <= 1'b0;		
                    end
                end
                PROCESSING: begin
						  //Quản lí tắt reset thanh ghi của sche khi block moi va comp khi input mới
						  reset_n_sche_reg <= 1'b1;
					 
                    // Quản lý việc load data
						  
                    if (loading_active && wrapper_data_valid && load_counter < 16) begin
                        load_counter <= load_counter + 1;   // Tăng bộ đếm load
                        
                        if (load_counter == 15) begin
                            loading_active <= 1'b0;     // Kết thúc load data
                            write_enable_in <= 1'b0;    // Tắt tín hiệu ghi
                        end
                    end

                    // Truyền dữ liệu
                    if (round_counter < 64) begin
                        Wt_to_comp <= Wt_from_sche;
              
                    end 
                end
            endcase
        end
    end

    
	 assign start_to_comp = start;
	 assign hash_output = hash_final_from_comp;
	 assign done = done_from_comp;
    assign STN_to_sche = STN_from_comp;              // Truyền STN từ comp đến sche trực tiếp
    assign round_t = round_counter;                  
    assign message_word_in = (loading_active && wrapper_data_valid) ? wrapper_data : 32'b0; 
    assign message_word_addr = (loading_active) ? load_counter : 4'b0; 
	 
	 //Logic reset thanh ghi H của comp
	 assign oResetn_new_input_to_comp = (state == IDLE && start) ? iResetn_new_input_to_comp : 1'b1;
	 

endmodule