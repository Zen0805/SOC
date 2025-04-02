//-----------------------------------------------------------------------------
// Module: maj_func
// Chức năng: Tính hàm Maj (Majority) của SHA-256.
//            Maj(x, y, z) = (x & y) ^ (x & z) ^ (y & z)
//-----------------------------------------------------------------------------
module maj_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);

    assign out = (x & y) ^ (x & z) ^ (y & z);

endmodule