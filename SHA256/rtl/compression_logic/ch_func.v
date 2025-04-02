//-----------------------------------------------------------------------------
// Module: ch_func
// Chức năng: Tính hàm Ch (Choice) của SHA-256.
//            Ch(x, y, z) = (x & y) ^ (~x & z)
//-----------------------------------------------------------------------------
module ch_func (
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [31:0] z,
    output wire [31:0] out
);

    // Dùng toán tử bitwise: & (AND), ~ (NOT), ^ (XOR)
    assign out = (x & y) ^ (~x & z);

endmodule