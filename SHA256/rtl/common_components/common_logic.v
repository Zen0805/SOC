
module adder_32bit (
    // --- Đầu vào ---
    input wire [31:0] a,     // Số thứ nhất mày muốn cộng (32 bit)
    input wire [31:0] b,     // Số thứ hai mày muốn cộng (32 bit)

    // --- Đầu ra ---
    output wire [31:0] sum    
);
    assign sum = a + b;

endmodule // Kết thúc module adder_32bit



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


module sigma0_func_compression (
    input wire [31:0] x,
    output wire [31:0] out
);

    wire [31:0] rotr2_x;
    wire [31:0] rotr13_x;
    wire [31:0] rotr22_x;

    assign rotr2_x  = {x[1:0], x[31:2]};
	 
    assign rotr13_x = {x[12:0], x[31:13]};
	 
    assign rotr22_x = {x[21:0], x[31:22]};

   
    assign out = rotr2_x ^ rotr13_x ^ rotr22_x;

endmodule


module sigma1_func_compression (
    input wire [31:0] x,
    output wire [31:0] out
);

    wire [31:0] rotr6_x;
    wire [31:0] rotr11_x;
    wire [31:0] rotr25_x;

    assign rotr6_x  = {x[5:0], x[31:6]};
  
    assign rotr11_x = {x[10:0], x[31:11]};
    
    assign rotr25_x = {x[24:0], x[31:25]};


    assign out = rotr6_x ^ rotr11_x ^ rotr25_x;

endmodule



module sigma0_func_schedule (
    input wire [31:0] x, 
    output wire [31:0] out
);
 
    wire [31:0] rotr7_x;   
    wire [31:0] rotr18_x; 
    wire [31:0] shr3_x;   

    assign rotr7_x  = {x[6:0], x[31:7]};
    assign rotr18_x = {x[17:0], x[31:18]};
    assign shr3_x   = x >> 3;

    assign out = rotr7_x ^ rotr18_x ^ shr3_x;

endmodule



module sigma1_func_schedule (
    input wire [31:0] x,   
    output wire [31:0] out  
);

    wire [31:0] rotr17_x; 
    wire [31:0] rotr19_x; 
    wire [31:0] shr10_x;  

    assign rotr17_x = {x[16:0], x[31:17]};
    assign rotr19_x = {x[18:0], x[31:19]};
    assign shr10_x  = x >> 10;

    assign out = rotr17_x ^ rotr19_x ^ shr10_x;

endmodule