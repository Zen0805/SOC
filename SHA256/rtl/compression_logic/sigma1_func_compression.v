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