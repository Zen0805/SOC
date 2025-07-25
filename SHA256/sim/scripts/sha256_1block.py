import struct

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

def generate_hash(words):
    """Return a SHA-256 hash from the 16 words (32-bit each) passed."""
    if len(words) != 16:
        raise ValueError("Input must be exactly 16 words (32-bit each).")

    # Chuyển 16 words thành message block (512 bits)
    message_block = b''.join(struct.pack('>I', word) for word in words)

    # Setting Initial Hash Value
    h0 = 0x6a09e667
    h1 = 0xbb67ae85
    h2 = 0x3c6ef372
    h3 = 0xa54ff53a
    h4 = 0x510e527f
    h5 = 0x9b05688c
    h6 = 0x1f83d9ab
    h7 = 0x5be0cd19

    # Prepare message schedule
    message_schedule = []
    for t in range(0, 64):
        if t <= 15:
            message_schedule.append(message_block[t*4:(t*4)+4])
        else:
            term1 = _sigma1(int.from_bytes(message_schedule[t-2], 'big'))
            term2 = int.from_bytes(message_schedule[t-7], 'big')
            term3 = _sigma0(int.from_bytes(message_schedule[t-15], 'big'))
            term4 = int.from_bytes(message_schedule[t-16], 'big')
            schedule = ((term1 + term2 + term3 + term4) % 2**32).to_bytes(4, 'big')
            message_schedule.append(schedule)

    assert len(message_schedule) == 64

    # Initialize working variables
    a = h0
    b = h1
    c = h2
    d = h3
    e = h4
    f = h5
    g = h6
    h = h7

    # Iterate for t=0 to 63
    for t in range(64):
        t1 = ((h + _capsigma1(e) + _ch(e, f, g) + K[t] +
               int.from_bytes(message_schedule[t], 'big')) % 2**32)
        t2 = (_capsigma0(a) + _maj(a, b, c)) % 2**32
        h = g
        g = f
        f = e
        e = (d + t1) % 2**32
        d = c
        c = b
        b = a
        a = (t1 + t2) % 2**32

    # Compute intermediate hash value
    h0 = (h0 + a) % 2**32
    h1 = (h1 + b) % 2**32
    h2 = (h2 + c) % 2**32
    h3 = (h3 + d) % 2**32
    h4 = (h4 + e) % 2**32
    h5 = (h5 + f) % 2**32
    h6 = (h6 + g) % 2**32
    h7 = (h7 + h) % 2**32

    return ((h0).to_bytes(4, 'big') + (h1).to_bytes(4, 'big') +
            (h2).to_bytes(4, 'big') + (h3).to_bytes(4, 'big') +
            (h4).to_bytes(4, 'big') + (h5).to_bytes(4, 'big') +
            (h6).to_bytes(4, 'big') + (h7).to_bytes(4, 'big'))

def _sigma0(num: int):
    """As defined in the specification."""
    num = (_rotate_right(num, 7) ^
           _rotate_right(num, 18) ^
           (num >> 3))
    return num

def _sigma1(num: int):
    """As defined in the specification."""
    num = (_rotate_right(num, 17) ^
           _rotate_right(num, 19) ^
           (num >> 10))
    return num

def _capsigma0(num: int):
    """As defined in the specification."""
    num = (_rotate_right(num, 2) ^
           _rotate_right(num, 13) ^
           _rotate_right(num, 22))
    return num

def _capsigma1(num: int):
    """As defined in the specification."""
    num = (_rotate_right(num, 6) ^
           _rotate_right(num, 11) ^
           _rotate_right(num, 25))
    return num

def _ch(x: int, y: int, z: int):
    """As defined in the specification."""
    return (x & y) ^ (~x & z)

def _maj(x: int, y: int, z: int):
    """As defined in the specification."""
    return (x & y) ^ (x & z) ^ (y & z)

def _rotate_right(num: int, shift: int, size: int = 32):
    """Rotate an integer right."""
    return (num >> shift) | (num << size - shift)

if __name__ == "__main__":
    # 16 words đầu vào
    # words = [
    #     0x00000010, 0x00000011, 0x00000012, 0x00000013,
    #     0x00000014, 0x00000000, 0x00000000, 0x00000000,
    #     0x00000000, 0x00000000, 0x00000000, 0x00000000,
    #     0x00000000, 0x00000000, 0x00000000, 0x0000001f
    # ]
    
    # words = [
        # 0x00000010, 0x00000011, 0x00000012, 0x00000013,
        # 0x00000014, 0x00000015, 0x00000016, 0x00000017,
        # 0x00000018, 0x00000019, 0x0000001a, 0x0000001b,
        # 0x0000001c, 0x0000001d, 0x0000001e, 0x0000001f
    # ]
    
    # words = [
    #     0x0000001f, 0x0000001e, 0x0000001d, 0x0000001c,
    #     0x0000001b, 0x0000001a, 0x00000019, 0x00000018,
    #     0x00000017, 0x00000016, 0x00000015, 0x00000014,
    #     0x00000013, 0x00000012, 0x00000011, 0x00000010
    # ]
    
    
    words = [
        0x54686973, 0x20697320, 0x61207465, 0x7374206d,
        0x65737361, 0x67652074, 0x68617420, 0x77696c6c,
        0x20646566, 0x696e6974, 0x656c7920, 0x7370616e,
        0x2074776f, 0x20534841, 0x2d323536, 0x20626c6f
]
    
    # Tính hash
    hash_value = generate_hash(words)
    print(hash_value.hex())