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