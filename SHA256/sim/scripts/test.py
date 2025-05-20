def unpad_sha256_message(padded_message: bytes) -> bytes | None:
    """
    Attempts to unpad a SHA-256 padded message to retrieve the original byte sequence.

    Args:
        padded_message: The padded message as a byte string. Its length
                        must be a multiple of 64 bytes.

    Returns:
        The original byte sequence if unpadding is successful, otherwise None.
        Returns None if the padding format seems incorrect.
    """
    if len(padded_message) == 0 or len(padded_message) % 64 != 0:
        print("Lỗi: Độ dài thông điệp đã padding phải là bội số của 64 byte và khác 0.")
        return None

    try:
        original_length_bits = int.from_bytes(padded_message[-8:], 'big')
    except Exception as e:
        print(f"Lỗi khi đọc độ dài gốc: {e}")
        return None

    original_length_bytes = original_length_bits // 8
    if original_length_bits % 8 != 0:
        print("Cảnh báo: Độ dài gốc (bit) không phải là bội số của 8. "
              "Hàm này giả định thông điệp gốc là một số byte hoàn chỉnh.")

    content_with_padding_markers = padded_message[:-8]

    if original_length_bytes > len(content_with_padding_markers):
        print("Lỗi: Độ dài gốc được chỉ định trong padding lớn hơn nội dung có sẵn.")
        return None

    original_message_candidate = content_with_padding_markers[:original_length_bytes]
    
    if original_length_bytes < len(content_with_padding_markers):
        marker_byte = content_with_padding_markers[original_length_bytes]
        if marker_byte != 0x80:
            print("Lỗi: Không tìm thấy byte đánh dấu 0x80 ở vị trí chính xác.")
            return None
        
        padding_zeros_start_index = original_length_bytes + 1
        for i in range(padding_zeros_start_index, len(content_with_padding_markers)):
            if content_with_padding_markers[i] != 0x00:
                print(f"Lỗi: Tìm thấy byte khác 0 trong vùng đệm zero tại chỉ số {i - len(original_message_candidate) - 1} sau 0x80.")
                return None
    elif original_length_bytes == len(content_with_padding_markers):
        if original_length_bytes == 0: 
            if not content_with_padding_markers or content_with_padding_markers[0] != 0x80:
                 print("Lỗi: Định dạng padding không chính xác cho chuỗi gốc rỗng.")
                 return None
        pass # No explicit zero bytes between 0x80 and length field

    return original_message_candidate

if __name__ == "__main__":
    # Nhập chuỗi hex từ người dùng
    hex_input_string = input("Nhập chuỗi hex của dữ liệu đã được padding SHA-256: ").strip()

    try:
        # Chuyển đổi chuỗi hex thành bytes
        padded_bytes_input = bytes.fromhex(hex_input_string)
    except ValueError:
        print("Lỗi: Chuỗi hex không hợp lệ. Vui lòng chỉ nhập các ký tự 0-9 và a-f (không phân biệt hoa thường).")
        exit()

    print(f"\nDữ liệu đã padding (dạng bytes từ input): {padded_bytes_input}")
    print(f"Độ dài dữ liệu đã padding: {len(padded_bytes_input)} bytes")

    # Thực hiện unpadding
    unpadded_original_bytes = unpad_sha256_message(padded_bytes_input)

    if unpadded_original_bytes is not None:
        print(f"\nThông điệp gốc (dạng bytes sau khi unpad): {unpadded_original_bytes}")
        print(f"Thông điệp gốc (dạng hex sau khi unpad): {unpadded_original_bytes.hex()}")
        print(f"Độ dài thông điệp gốc: {len(unpadded_original_bytes)} bytes")

        # Cố gắng decode thành string với các encoding phổ biến
        print("\nCố gắng giải mã thành chuỗi string (thử các encoding phổ biến):")
        encodings_to_try = ['utf-8', 'ascii', 'latin-1', 'cp1252'] # Thêm cp1252
        found_decoding = False
        for encoding in encodings_to_try:
            try:
                recovered_string = unpadded_original_bytes.decode(encoding)
                print(f"  Thử với '{encoding}': '{recovered_string}'")
                # Bạn có thể thêm logic kiểm tra xem chuỗi có "ý nghĩa" không ở đây
                # Ví dụ, kiểm tra ký tự không in được, v.v.
                # Tuy nhiên, việc này phức tạp và không đảm bảo.
                found_decoding = True # Ít nhất một lần decode thành công
            except UnicodeDecodeError:
                print(f"  Không thể giải mã bằng '{encoding}'.")
            except Exception as e:
                print(f"  Lỗi không xác định khi giải mã bằng '{encoding}': {e}")
        
        if not found_decoding and unpadded_original_bytes:
             print("  Không thể giải mã thành chuỗi văn bản dễ đọc với các encoding đã thử.")
        elif not unpadded_original_bytes:
             print("  Thông điệp gốc là rỗng.")


    else:
        print("\nKhông thể thực hiện unpadding. Dữ liệu padding có thể không chính xác.")

    print("\n--- Ví dụ sử dụng ---")
    print("Để thử nghiệm, bạn có thể chạy file padding trước, copy output hex của nó,")
    print("sau đó dán vào đây khi được yêu cầu.")
    print("Ví dụ, nếu bạn pad chuỗi 'hello':")
    print("Padded hex có thể là: 68656c6c6f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028")
    print("(Lưu ý: 0028 ở cuối là 40 bits = 5 bytes * 8)")