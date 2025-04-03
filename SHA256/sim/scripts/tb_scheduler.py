# Triển khai Message Scheduler cho SHA-256 trong Python
# Tính toán W[t] từ t=0 đến t=63 dựa trên 16 từ ban đầu M[0] đến M[15]

def rotr(x, n):
    """Hàm xoay phải (Rotate Right) n bit cho số 32-bit"""
    x = x & 0xFFFFFFFF  # Đảm bảo x là 32-bit
    return ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF

def shr(x, n):
    """Hàm dịch phải logic (Shift Right) n bit cho số 32-bit"""
    return x >> n

def sigma0(x):
    """Hàm sigma0 trong SHA-256: σ₀(x) = ROTR⁷(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)"""
    return rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3)

def sigma1(x):
    """Hàm sigma1 trong SHA-256: σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)"""
    return rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10)

def message_scheduler(message_block):
    """
    Tính toán lịch trình thông điệp W[t] cho SHA-256
    Input: message_block - danh sách 16 từ 32-bit (M[0] đến M[15])
    Output: danh sách 64 từ W[0] đến W[63]
    """
    # Khởi tạo W với 16 từ đầu tiên từ message_block
    W = list(message_block)
    
    # Tính toán W[t] cho t từ 16 đến 63
    for t in range(16, 64):
        # Công thức: W[t] = W[t-16] + σ0(W[t-15]) + W[t-7] + σ1(W[t-2])
        Wt = (W[t-16] + sigma0(W[t-15]) + W[t-7] + sigma1(W[t-2])) & 0xFFFFFFFF
        W.append(Wt)
    
    return W

# Hàm in kết quả để so sánh với testbench
def print_schedule(W):
    """In danh sách W[t] dưới dạng hex để dễ so sánh"""
    for t, wt in enumerate(W):
        print(f"W[{t}] = 0x{wt:08x}")

# Ví dụ kiểm tra
if __name__ == "__main__":
    # Tạo khối thông điệp ban đầu giống testbench Verilog
    # M[i] = i + 0x10 (tương tự testbench: i + 16)
    message_block = [i + 0x10 for i in range(16)]
    
    print("Initial message block (M[0] to M[15]):")
    for i, m in enumerate(message_block):
        print(f"M[{i}] = 0x{m:08x}")
    
    # Tính toán lịch trình thông điệp
    W = message_scheduler(message_block)
    
    print("\nMessage Schedule (W[0] to W[63]):")
    print_schedule(W)