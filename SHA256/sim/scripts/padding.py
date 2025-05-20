def pad_message_sha256(message: bytes) -> bytes:
    """
    Pads the input message according to SHA-256 specifications.

    Args:
        message: The original message as a byte string.

    Returns:
        The padded message as a byte string, ready for SHA-256 processing.
        The length of the returned byte string will be a multiple of 64 bytes (512 bits).
    """
    original_length_bits = len(message) * 8

    # 1. Append a single '1' bit (byte 0x80).
    padded_message = message + b'\x80'

    # 2. Append '0' bits (0x00 bytes) until message length in bytes is 56 (mod 64).
    #    This leaves 8 bytes (64 bits) for the original length.
    current_length_bytes_after_80 = len(padded_message)
    num_zero_bytes_to_add = (56 - (current_length_bytes_after_80 % 64)) % 64
    
    padded_message += b'\x00' * num_zero_bytes_to_add

    # 3. Append the original length of the message (before any padding),
    #    as a 64-bit big-endian integer.
    padded_message += original_length_bits.to_bytes(8, 'big')
        
    return padded_message

if __name__ == "__main__":
    # Nhập chuỗi từ người dùng
    user_input_string = input("Nhập chuỗi bạn muốn padding: ")

    # Chuyển đổi chuỗi người dùng nhập thành bytes (sử dụng UTF-8 encoding)
    # Bạn có thể chọn encoding khác nếu cần, ví dụ: 'ascii'
    message_to_pad = user_input_string.encode('utf-8')

    print(f"\nChuỗi gốc (dạng string): '{user_input_string}'")
    print(f"Chuỗi gốc (dạng bytes, UTF-8): {message_to_pad}")
    print(f"Độ dài chuỗi gốc: {len(message_to_pad)} bytes ({len(message_to_pad)*8} bits)")

    # Thực hiện padding
    padded_data = pad_message_sha256(message_to_pad)

    print(f"\nDữ liệu đã được padding (dạng hex):")
    print(padded_data.hex())
    print(f"Độ dài dữ liệu đã padding: {len(padded_data)} bytes ({len(padded_data)*8} bits)")
    print(f"Số block 512-bit (64 byte) trong dữ liệu đã padding: {len(padded_data) // 64}")

    # Ví dụ:
    # Nếu bạn nhập "abc"
    # Chuỗi gốc (dạng string): 'abc'
    # Chuỗi gốc (dạng bytes, UTF-8): b'abc'
    # Độ dài chuỗi gốc: 3 bytes (24 bits)

    # Dữ liệu đã được padding (dạng hex):
    # 616263800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018
    # Độ dài dữ liệu đã padding: 64 bytes (512 bits)
    # Số block 512-bit (64 byte) trong dữ liệu đã padding: 1

    # Nếu bạn nhập một chuỗi dài hơn, ví dụ 60 ký tự 'a'
    # user_input_string = 'a' * 60
    # ...
    # Độ dài chuỗi gốc: 60 bytes (480 bits)
    # ...
    # Độ dài dữ liệu đã padding: 128 bytes (1024 bits)
    # Số block 512-bit (64 byte) trong dữ liệu đã padding: 2