import struct

# Các hằng số K và các hàm (_sigma0, _sigma1, etc.) giữ nguyên như trước
K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

def _rotate_right(num: int, shift: int, size: int = 32):
    return ((num >> shift) | (num << (size - shift))) & ((1 << size) - 1)

def _sigma0(num: int):
    return _rotate_right(num, 7) ^ _rotate_right(num, 18) ^ (num >> 3)

def _sigma1(num: int):
    return _rotate_right(num, 17) ^ _rotate_right(num, 19) ^ (num >> 10)

def _capsigma0(num: int):
    return _rotate_right(num, 2) ^ _rotate_right(num, 13) ^ _rotate_right(num, 22)

def _capsigma1(num: int):
    return _rotate_right(num, 6) ^ _rotate_right(num, 11) ^ _rotate_right(num, 25)

def _ch(x: int, y: int, z: int):
    return (x & y) ^ (~x & z)

def _maj(x: int, y: int, z: int):
    return (x & y) ^ (x & z) ^ (y & z)


def generate_hash_from_padded_data(padded_message: bytes) -> bytes | None:
    """
    Return a SHA-256 hash from the already padded message.
    The padded_message must be a byte string whose length is a multiple of 64 bytes (512 bits).
    """
    if len(padded_message) == 0 or len(padded_message) % 64 != 0:
        print("Lỗi: Độ dài thông điệp đã padding phải là bội số của 64 byte và khác 0.")
        return None

    # Initial Hash Values (h0 to h7)
    h_vars = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]

    num_blocks = len(padded_message) // 64

    for i in range(num_blocks):
        current_block_bytes = padded_message[i*64 : (i+1)*64]
        w = [0] * 64
        for t in range(16):
            w[t] = int.from_bytes(current_block_bytes[t*4 : t*4+4], 'big')

        for t in range(16, 64):
            s0 = _sigma0(w[t-15])
            s1 = _sigma1(w[t-2])
            w[t] = (w[t-16] + s0 + w[t-7] + s1) % (2**32)

        a = h_vars[0]
        b = h_vars[1]
        c = h_vars[2]
        d = h_vars[3]
        e = h_vars[4]
        f = h_vars[5]
        g = h_vars[6]
        h_loop_var = h_vars[7]

        for t in range(64):
            S1 = _capsigma1(e)
            ch_val = _ch(e, f, g)
            temp1 = (h_loop_var + S1 + ch_val + K[t] + w[t]) % (2**32)
            S0 = _capsigma0(a)
            maj_val = _maj(a, b, c)
            temp2 = (S0 + maj_val) % (2**32)

            h_loop_var = g
            g = f
            f = e
            e = (d + temp1) % (2**32)
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % (2**32)

        h_vars[0] = (h_vars[0] + a) % (2**32)
        h_vars[1] = (h_vars[1] + b) % (2**32)
        h_vars[2] = (h_vars[2] + c) % (2**32)
        h_vars[3] = (h_vars[3] + d) % (2**32)
        h_vars[4] = (h_vars[4] + e) % (2**32)
        h_vars[5] = (h_vars[5] + f) % (2**32)
        h_vars[6] = (h_vars[6] + g) % (2**32)
        h_vars[7] = (h_vars[7] + h_loop_var) % (2**32)

    return b''.join(val.to_bytes(4, 'big') for val in h_vars)

if __name__ == "__main__":
    print("Chương trình tính SHA-256 từ dữ liệu đã được padding.")
    print("Vui lòng nhập dữ liệu đã padding dưới dạng chuỗi hex.")
    print("Độ dài chuỗi hex phải là bội số của 128 ký tự (tương ứng với các block 512-bit).")
    print("Ví dụ: 128 ký tự (1 block), 256 ký tự (2 block), 384 ký tự (3 block), v.v.")

    hex_input_string = input("Nhập chuỗi hex của dữ liệu đã padding: ").strip()

    # Kiểm tra độ dài chuỗi hex: phải là bội số của 128 và không rỗng
    if not hex_input_string or len(hex_input_string) % 128 != 0:
        print("Lỗi: Độ dài chuỗi hex không hợp lệ.")
        print("Phải là bội số của 128 ký tự (ví dụ: 128, 256, 384,...) và không được rỗng.")
        exit()
    
    # Kiểm tra ký tự hex hợp lệ
    try:
        # Chuyển đổi chuỗi hex thành bytes
        padded_bytes_input = bytes.fromhex(hex_input_string)
    except ValueError:
        print("Lỗi: Chuỗi hex chứa ký tự không hợp lệ.")
        print("Vui lòng chỉ nhập các ký tự 0-9 và a-f (không phân biệt hoa thường).")
        exit()

    print(f"\nDữ liệu đã padding (dạng bytes từ input): {padded_bytes_input}")
    print(f"Độ dài dữ liệu đã padding: {len(padded_bytes_input)} bytes ({len(padded_bytes_input)*8} bits)")
    print(f"Số block 512-bit: {len(padded_bytes_input) // 64}")


    # Tính toán hash SHA-256
    final_hash = generate_hash_from_padded_data(padded_bytes_input)

    if final_hash:
        print(f"\nKết quả SHA-256 Hash (dạng hex):")
        print(final_hash.hex())
    else:
        print("\nKhông thể tính toán hash. Vui lòng kiểm tra lại dữ liệu đầu vào.")

    # print("\n--- Ví dụ để kiểm tra ---")
    # print("1. Padded 'abc' (1 block - 128 ký tự hex):")
    # print("   Input hex: 616263800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018")
    # print("   Expected hash: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    
    # print("\n2. Padded 'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmno' (56 byte message, 2 blocks - 256 ký tự hex):")
    # padded_56_byte_msg_hex = (
    #     "61626364656667686263646566676869636465666768696a6465666768696a6b"
    #     "65666768696a6b6c666768696a6b6c6d6768696a6b6c6d6e68696a6b6c6d6e6f"
    #     "80" + "00" * 63 + "00000000000001c0"
    # )
    # print(f"   Input hex: {padded_56_byte_msg_hex}")
    # print("   Expected hash: cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")

    # print("\n3. Padded 'Cryptography is the practice and study of techniques for secure communication in the presence of third parties. It involves constructing and analyzing protocols.' (150 byte message, 3 blocks - 384 ký tự hex):")
    # padded_150_byte_msg_hex = (
    #     "43727970746f6772617068792069732074686520707261637469636520616e64207374756479206f6620746563686e697175657320666f722073656375726520636f6d6d756e69636174696f6e20696e207468652070726573656e6365206f6620746869726420706172746965732e20497420696e766f6c76657320636f6e737472756374696e6720616e6420616e616c797a696e672070726f746f636f6c732e"
    #     "80" + "00" * 33 + "00000000000004b0" # 150 byte message, 0x04b0 = 1200 bits
    # )
    # print(f"   Input hex: {padded_150_byte_msg_hex}")
    # print("   Expected hash: 2d99534232158cd38006361096197407501e1aff2094801420981b2013690556")