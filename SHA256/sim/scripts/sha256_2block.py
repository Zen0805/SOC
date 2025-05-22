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

def _rotate_right(num: int, shift: int, size: int = 32):
    """Rotate an integer right."""
    return (num >> shift) | (num << (size - shift)) & (2**size - 1)

def _sigma0(num: int):
    """As defined in the specification."""
    return _rotate_right(num, 7) ^ _rotate_right(num, 18) ^ (num >> 3)

def _sigma1(num: int):
    """As defined in the specification."""
    return _rotate_right(num, 17) ^ _rotate_right(num, 19) ^ (num >> 10)

def _capsigma0(num: int):
    """As defined in the specification."""
    return _rotate_right(num, 2) ^ _rotate_right(num, 13) ^ _rotate_right(num, 22)

def _capsigma1(num: int):
    """As defined in the specification."""
    return _rotate_right(num, 6) ^ _rotate_right(num, 11) ^ _rotate_right(num, 25)

def _ch(x: int, y: int, z: int):
    """As defined in the specification."""
    return (x & y) ^ (~x & z)

def _maj(x: int, y: int, z: int):
    """As defined in the specification."""
    return (x & y) ^ (x & z) ^ (y & z)

def _process_block(block: bytes, current_hash: list):
    """Process a single 512-bit block and update the hash values."""
    if len(block) != 64:
        raise ValueError("Block must be exactly 64 bytes (512 bits).")

    # Unpack current hash values
    h0, h1, h2, h3, h4, h5, h6, h7 = current_hash

    # Prepare message schedule
    message_schedule = []
    for t in range(0, 64):
        if t <= 15:
            message_schedule.append(block[t*4:(t*4)+4])
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
        t1 = (h + _capsigma1(e) + _ch(e, f, g) + K[t] + int.from_bytes(message_schedule[t], 'big')) % 2**32
        t2 = (_capsigma0(a) + _maj(a, b, c)) % 2**32
        h = g
        g = f
        f = e
        e = (d + t1) % 2**32
        d = c
        c = b
        b = a
        a = (t1 + t2) % 2**32

    # Update hash values
    h0 = (h0 + a) % 2**32
    h1 = (h1 + b) % 2**32
    h2 = (h2 + c) % 2**32
    h3 = (h3 + d) % 2**32
    h4 = (h4 + e) % 2**32
    h5 = (h5 + f) % 2**32
    h6 = (h6 + g) % 2**32
    h7 = (h7 + h) % 2**32

    return [h0, h1, h2, h3, h4, h5, h6, h7]

def _split_into_blocks(message: bytes):
    """Split the message into 64-byte (512-bit) blocks."""
    if len(message) % 64 != 0:
        raise ValueError("Message length must be a multiple of 64 bytes (512 bits).")
    return [message[i:i+64] for i in range(0, len(message), 64)]

def sha256(message: bytes):
    """Compute SHA-256 hash of the padded message."""
    # Initial hash values
    current_hash = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]

    # Split message into blocks
    blocks = _split_into_blocks(message)

    # Process each block
    for block in blocks:
        current_hash = _process_block(block, current_hash)

    # Concatenate hash values into a 256-bit (32-byte) hash
    hash_value = b''.join(h.to_bytes(4, 'big') for h in current_hash)
    return hash_value

if __name__ == "__main__":
    # Ví dụ 1: 1 block (16 words, 512 bits)
    # words = [
    #     0x61646277, 0x70696662, 0x61776670, 0x69616662,
    #     0x7366736b, 0x61666a62, 0x77666961, 0x6a776276,
    #     0x66617078, 0x62616677, 0x66616a69, 0x62667769,
    #     0x66626161, 0x6469776a, 0x6277696f, 0x66627561,
    # ]
    
    words = [
        0x54686973, 0x20697320, 0x61207465, 0x7374206d,
        0x65737361, 0x67652074, 0x68617420, 0x77696c6c,
        0x20646566, 0x696e6974, 0x656c7920, 0x7370616e,
        0x2074776f, 0x20534841, 0x2d323536, 0x20626c6f,
    ]

    
    message_1block = b''.join(struct.pack('>I', word) for word in words)
    hash_value = sha256(message_1block)
    print("Hash của 1 block:", hash_value.hex())

    #Ví dụ 2: 2 blocks (32 words, 1024 bits)
    # words_2blocks = words + [
    #     0x73706f69, 0x67626167, 0x69707767, 0x62617767,
    #     0x61800000, 0x00000000, 0x00000000, 0x00000000,
    #     0x00000000, 0x00000000, 0x00000000, 0x00000000,
    #     0x00000000, 0x00000000, 0x00000000, 0x00000288
    # ]
    
    words_2blocks = words + [
        0x636b7320, 0x61667465, 0x72207061, 0x6464696e,
        0x67800000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000288,
    ]
    
    
    
    message_2blocks = b''.join(struct.pack('>I', word) for word in words_2blocks)
    hash_value_2blocks = sha256(message_2blocks)
    print("Hash của 2 blocks:", hash_value_2blocks.hex())