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