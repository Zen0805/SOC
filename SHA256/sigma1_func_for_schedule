//-----------------------------------------------------------------------------
// Module: sigma1_func
// Tác giả: Vẫn là tao
// Chức năng: Tính hàm sigma1 (σ₁) của SHA-256.
//            σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)
//-----------------------------------------------------------------------------
module sigma1_func_for_schedule (
    input wire [31:0] x,    // Đầu vào 32-bit
    output wire [31:0] out  // Kết quả sigma1(x) 32-bit
);

    // --- Tính toán trung gian ---
    wire [31:0] rotr17_x; // Rotate Right 17 bits
    wire [31:0] rotr19_x; // Rotate Right 19 bits
    wire [31:0] shr10_x;  // Shift Right 10 bits (Logical)

    // --- Logic thực hiện các phép toán ---
    assign rotr17_x = {x[16:0], x[31:17]};
    assign rotr19_x = {x[18:0], x[31:19]};
    assign shr10_x  = x >> 10;

    // Tính sigma1: ROTR17(x) ^ ROTR19(x) ^ SHR10(x)
    assign out = rotr17_x ^ rotr19_x ^ shr10_x;

endmodule