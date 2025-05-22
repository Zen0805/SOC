def format_hex_input_to_words_list(hex_input_string: str) -> str | None:
    """
    Formats a long hex string (representing 512 or 1024 bits) into
    a Python list-like string of 32-bit hex words.

    Args:
        hex_input_string: The input hex string (e.g., 128 or 256 characters).

    Returns:
        A string formatted as a Python list of hex words, or None if input is invalid.
    """
    hex_input_string = hex_input_string.strip().lower() # Chuẩn hóa input

    # Kiểm tra độ dài input (512 bits = 64 bytes = 128 hex chars; 1024 bits = 128 bytes = 256 hex chars)
    if len(hex_input_string) not in [128, 256]:
        print("Lỗi: Độ dài chuỗi hex đầu vào phải là 128 (cho 512 bit) hoặc 256 (cho 1024 bit) ký tự.")
        return None

    # Kiểm tra xem có phải là ký tự hex hợp lệ không
    try:
        bytes.fromhex(hex_input_string) # Thử chuyển đổi, nếu lỗi sẽ raise ValueError
    except ValueError:
        print("Lỗi: Chuỗi đầu vào chứa ký tự không phải hex.")
        return None

    words_list_str_elements = []
    word_size_hex_chars = 8  # Mỗi word 32-bit là 8 ký tự hex

    for i in range(0, len(hex_input_string), word_size_hex_chars):
        word_hex = hex_input_string[i:i + word_size_hex_chars]
        formatted_word = "0x" + word_hex
        words_list_str_elements.append(formatted_word)

    # Bắt đầu xây dựng chuỗi output
    output_string = "words = [\n"
    words_per_line = 4 # Số lượng word trên mỗi dòng, giống như trong ảnh

    num_total_words = len(words_list_str_elements)
    for i in range(num_total_words):
        if i % words_per_line == 0:
            output_string += "    "  # Thụt lề cho mỗi dòng mới

        output_string += words_list_str_elements[i]

        # Thêm dấu phẩy nếu không phải là phần tử cuối cùng của toàn bộ danh sách
        if i < num_total_words - 1:
            output_string += ","

        # Thêm ký tự xuống dòng nếu đó là cuối một dòng (theo words_per_line)
        # hoặc nếu đó là phần tử cuối cùng của toàn bộ danh sách
        if (i + 1) % words_per_line == 0 or i == num_total_words - 1:
            output_string += "\n"
        else:
            # Thêm dấu cách sau dấu phẩy nếu không phải cuối dòng
            output_string += " "
            
    output_string += "]"
    return output_string

if __name__ == "__main__":
    print("Chương trình định dạng chuỗi hex thành danh sách Python words.")
    print("Vui lòng nhập chuỗi hex (128 hoặc 256 ký tự).")
    
    input_hex = input("Nhập chuỗi hex: ")
    
    formatted_output = format_hex_input_to_words_list(input_hex)
    
    if formatted_output:
        print("\nOutput đã định dạng:")
        print(formatted_output)
    else:
        print("Không thể tạo output do đầu vào không hợp lệ.")

    # print("\nVí dụ:")
    # example_input_512bit = "55495480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018"
    # print(f"\nNếu nhập (512 bit):\n{example_input_512bit}")
    # print("\nOutput mong muốn:")
    # print(format_hex_input_to_words_list(example_input_512bit))

    # example_input_1024bit = "61626364656667686263646566676869636465666768696a6465666768696a6b65666768696a6b6c666768696a6b6c6d6768696a6b6c6d6e68696a6b6c6d6e6f80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0"
    # print(f"\nNếu nhập (1024 bit):\n{example_input_1024bit}")
    # print("\nOutput mong muốn:")
    # print(format_hex_input_to_words_list(example_input_1024bit))