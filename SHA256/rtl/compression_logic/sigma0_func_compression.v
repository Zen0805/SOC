//-----------------------------------------------------------------------------
// Module: Sigma0_func_for_compression
// Chức năng: Tính hàm Sigma0 hoa (Σ₀) của SHA-256 (dùng trong compression).
//            Σ₀(x) = ROTR²(x) ^ ROTR¹³(x) ^ ROTR²²(x)
//-----------------------------------------------------------------------------
module sigma0_func_compression (
    input wire [31:0] x,
    output wire [31:0] out
);

    wire [31:0] rotr2_x;
    wire [31:0] rotr13_x;
    wire [31:0] rotr22_x;

    // Rotate Right 2 bits: {lower 2 bits, upper 30 bits}
    assign rotr2_x  = {x[1:0], x[31:2]};
    // Rotate Right 13 bits: {lower 13 bits, upper 19 bits}
    assign rotr13_x = {x[12:0], x[31:13]};
    // Rotate Right 22 bits: {lower 22 bits, upper 10 bits}
    assign rotr22_x = {x[21:0], x[31:22]};

    // XOR các kết quả lại
    assign out = rotr2_x ^ rotr13_x ^ rotr22_x;

endmodule