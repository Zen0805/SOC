module sha256_top (
    input wire clk,                    // Đồng hồ hệ thống
    input wire reset_n,                // Reset active-low
    input wire start,                  // Tín hiệu bắt đầu từ NIOS II
    input wire [31:0] wrapper_data,    // Dữ liệu từ Avalon bus
    input wire wrapper_data_valid,     // Tín hiệu báo dữ liệu hợp lệ từ Avalon bus
    output wire wrapper_data_request,  // Yêu cầu dữ liệu từ Avalon bus
    output wire [255:0] hash_out,      // Kết quả băm SHA-256
    output wire done                   // Tín hiệu báo hoàn thành
);

    // --- Khai báo wire nội bộ với tên dễ nhận biết ---
    // Biến liên quan đến controller
    wire [31:0] message_word_in_ctrl;
    wire [3:0] message_word_addr_ctrl;
    wire write_enable_in_ctrl;
    wire start_to_sche_ctrl;
    wire start_to_comp_ctrl;
    wire [5:0] round_t_ctrl;
    wire STN_to_sche_ctrl;
    wire [31:0] Wt_from_sche_ctrl;
    wire [31:0] Wt_to_comp_ctrl;
    wire STN_from_comp_ctrl;
    wire done_from_comp_ctrl;

    // Biến liên quan đến compression
    wire [255:0] H_final_out_comp;

    // --- Khởi tạo module controller ---
    controller u_controller (
        .clk(clk),                     // Đồng hồ hệ thống
        .reset_n(reset_n),             // Reset hệ thống
        .start(start),                 // Bắt đầu từ NIOS II
        .wrapper_data(wrapper_data),   // Dữ liệu từ Avalon bus
        .wrapper_data_valid(wrapper_data_valid), // Dữ liệu hợp lệ
        .wrapper_data_request(wrapper_data_request), // Yêu cầu dữ liệu
        .message_word_in(message_word_in_ctrl), // Dữ liệu gửi sang scheduler
        .message_word_addr(message_word_addr_ctrl), // Địa chỉ gửi sang scheduler
        .write_enable_in(write_enable_in_ctrl), // Cho phép ghi vào scheduler
        .start_to_sche(start_to_sche_ctrl),     // Bắt đầu scheduler
        .start_to_comp(start_to_comp_ctrl),     // Bắt đầu compression
        .round_t(round_t_ctrl),                 // Round hiện tại
        .STN_to_sche(STN_to_sche_ctrl),         // STN đến scheduler
        .Wt_from_sche(Wt_from_sche_ctrl),       // Nhận Wt từ scheduler
        .Wt_to_comp(Wt_to_comp_ctrl),           // Gửi Wt sang compression
        .STN_from_comp(STN_from_comp_ctrl),     // Nhận STN từ compression
        .done_from_comp(done_from_comp_ctrl)    // Nhận tín hiệu hoàn thành

    );

    // --- Khởi tạo module message_scheduler ---
    message_scheduler u_scheduler (
        .clk(clk),                     // Đồng hồ hệ thống
        .reset_n(reset_n),             // Reset hệ thống
        .start_new_block(start_to_sche_ctrl), // Bắt đầu block mới
        .CtrlStart(start_to_sche_ctrl),     // Tín hiệu start (dùng chung start_to_sche_ctrl)
        .STN(STN_to_sche_ctrl),             // Tín hiệu STN từ controller
        .round_t(round_t_ctrl),             // Round hiện tại
        .message_word_in(message_word_in_ctrl), // Dữ liệu từ controller
        .message_word_addr(message_word_addr_ctrl), // Địa chỉ từ controller
        .write_enable_in(write_enable_in_ctrl), // Cho phép ghi từ controller
        .Wt_out(Wt_from_sche_ctrl)          // Gửi Wt về controller
    );

    // --- Khởi tạo module message_compression ---
    message_compression u_compression (
        .clk(clk),                     // Đồng hồ hệ thống
        .rst_n(reset_n),               // Reset hệ thống
        .start(start_to_comp_ctrl),    // Bắt đầu từ controller
        .Wt_in(Wt_to_comp_ctrl),       // Nhận Wt từ controller
        .H_final_out(H_final_out_comp),// Kết quả băm
        .done(done_from_comp_ctrl),    // Báo hoàn thành cho controller
        .STN(STN_from_comp_ctrl)       // Báo STN cho controller
    );

    // --- Gán kết quả ra ngoài module top-level ---
    assign hash_out = H_final_out_comp; // Gán kết quả băm ra ngoài
    assign done = done_from_comp_ctrl;  // Gán tín hiệu hoàn thành ra ngoài

endmodule