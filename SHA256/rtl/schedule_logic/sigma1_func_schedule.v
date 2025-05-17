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