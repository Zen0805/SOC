module maj_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);

    assign out = (x & y) ^ (x & z) ^ (y & z);

endmodule