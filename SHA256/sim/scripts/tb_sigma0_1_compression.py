def rotr(x, n, bits=32):
  """Xoay phải x đi n bit (mặc định 32 bit)."""
  mask = (1 << bits) - 1
  n = n % bits # Đảm bảo n nhỏ hơn số bit
  return ((x >> n) | (x << (bits - n))) & mask

def Sigma0_comp(x):
  """Tính hàm Sigma0 hoa (Σ₀) của SHA-256."""
  mask = 0xFFFFFFFF
  x = x & mask
  # Công thức: ROTR²(x) XOR ROTR¹³(x) XOR ROTR²²(x)
  return (rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22)) & mask

def Sigma1_comp(x):
  """Tính hàm Sigma1 hoa (Σ₁) của SHA-256."""
  mask = 0xFFFFFFFF
  x = x & mask
  # Công thức: ROTR⁶(x) XOR ROTR¹¹(x) XOR ROTR²⁵(x)
  return (rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25)) & mask

if __name__ == "__main__":
  while True:
    try:
      x_hex = input("Nhập giá trị x (hex, ví dụ 0xABCDEFFF): ")
      if not x_hex: break
      x_val = int(x_hex, 16)

      mask32 = 0xFFFFFFFF
      x_val &= mask32

      print(f"Giá trị nhập (đã mask 32-bit): 0x{x_val:08x}")

      result_S0 = Sigma0_comp(x_val)
      result_S1 = Sigma1_comp(x_val)

      print(f"Sigma0(x) = 0x{result_S0:08x}")
      print(f"Sigma1(x) = 0x{result_S1:08x}")
      print("-" * 20)

    except ValueError:
      print("Lỗi: Input không phải là số hex hợp lệ.")
    except Exception as e:
      print(f"Lỗi không xác định: {e}")