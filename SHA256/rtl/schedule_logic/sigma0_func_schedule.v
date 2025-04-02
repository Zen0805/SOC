//-----------------------------------------------------------------------------
// Module: sigma0_func_schedule
// Tác giả: ZenZ
// Chức năng: Tính hàm sigma0 (σ₀) của SHA-256.
//            σ₀(x) = ROTR⁷(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)
//-----------------------------------------------------------------------------
module sigma0_func_schedule (
    input wire [31:0] x,    // Đầu vào 32-bit
    output wire [31:0] out  // Kết quả sigma0(x) 32-bit
);

    // --- Tính toán trung gian ---
    wire [31:0] rotr7_x;  // Rotate Right 7 bits
    wire [31:0] rotr18_x; // Rotate Right 18 bits
    wire [31:0] shr3_x;   // Shift Right 3 bits (Logical)

    // --- Logic thực hiện các phép toán ---
    assign rotr7_x  = {x[6:0], x[31:7]};
    assign rotr18_x = {x[17:0], x[31:18]};
    assign shr3_x   = x >> 3;

    // Tính sigma0: ROTR7(x) ^ ROTR18(x) ^ SHR3(x)
    assign out = rotr7_x ^ rotr18_x ^ shr3_x;

endmodule