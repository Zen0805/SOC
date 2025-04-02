//-----------------------------------------------------------------------------
// Module: adder_32bit
// Tác giả: Thằng bạn của mày
// Chức năng: Cộng hai cái số 32-bit lại với nhau.
//            Đơn giản như đang giỡn, nhưng mà quan trọng à nha.
//-----------------------------------------------------------------------------
module adder_32bit (
    // --- Đầu vào ---
    input wire [31:0] a,     // Số thứ nhất mày muốn cộng (32 bit)
    input wire [31:0] b,     // Số thứ hai mày muốn cộng (32 bit)

    // --- Đầu ra ---
    output wire [31:0] sum    // Kết quả tổng của a + b (32 bit)
);

    // --- Logic chính ---
    // Dùng 'assign' để gán giá trị cho đầu ra 'sum' một cách liên tục.
    // Nghĩa là bất cứ khi nào 'a' hoặc 'b' thay đổi, 'sum' nó tự cập nhật theo.
    // Cái này là mạch tổ hợp (combinational logic), không cần clock gì hết.
    // Toán tử '+' trong Verilog nó tự xử lý vụ cộng bit luôn, khỏe re.
    assign sum = a + b;

endmodule // Kết thúc module adder_32bit