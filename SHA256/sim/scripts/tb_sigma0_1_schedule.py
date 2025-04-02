import sys

# --- Hằng số mặt nạ 32-bit ---
MASK_32 = 0xFFFFFFFF

# --- Hàm Rotate Right 32-bit ---
def rotr(n, bits, total_bits=32):
  """Thực hiện phép xoay phải n đi bits vị trí trong không gian total_bits."""
  n &= MASK_32 # Đảm bảo n là 32 bit trước khi xoay
  bits %= total_bits # Xử lý trường hợp bits >= total_bits
  if bits == 0:
      return n
  # Dịch phải n đi bits, và dịch trái n đi (total_bits - bits) rồi OR lại
  # Nhớ AND với MASK_32 sau mỗi phép dịch để giữ 32 bit
  right = (n >> bits) & MASK_32
  left = (n << (total_bits - bits)) & MASK_32
  return (right | left) & MASK_32

# --- Hàm Shift Right Logical 32-bit ---
def shr(n, bits):
  """Thực hiện phép dịch phải logic n đi bits vị trí."""
  # Trong Python, >> là dịch phải số học, nhưng với số dương (sau khi mask)
  # nó hoạt động như dịch phải logic.
  return (n >> bits) & MASK_32

# --- Hàm tính sigma0 ---
def sigma0(x):
  """Tính hàm sigma0 của SHA-256."""
  # σ₀(x) = ROTR⁷(x) ⊕ ROTR¹⁸(x) ⊕ SHR³(x)
  r7 = rotr(x, 7)
  r18 = rotr(x, 18)
  s3 = shr(x, 3)
  return (r7 ^ r18 ^ s3) & MASK_32

# --- Hàm tính sigma1 ---
def sigma1(x):
  """Tính hàm sigma1 của SHA-256."""
  # σ₁(x) = ROTR¹⁷(x) ⊕ ROTR¹⁹(x) ⊕ SHR¹⁰(x)
  r17 = rotr(x, 17)
  r19 = rotr(x, 19)
  s10 = shr(x, 10)
  return (r17 ^ r19 ^ s10) & MASK_32

# --- Hàm chính để chạy ---
if __name__ == "__main__":
  print("Chương trình kiểm tra hàm sigma0 và sigma1 của SHA-256.")
  print("Nhập giá trị 32-bit (dạng thập phân hoặc hexa bắt đầu bằng 0x).")
  print("Nhập 'q' để thoát.")

  while True:
    try:
      input_str = input("\nNhập giá trị x: ").strip()
      if input_str.lower() == 'q':
        break

      # Xử lý input dạng hexa hoặc thập phân
      if input_str.startswith('0x') or input_str.startswith('0X'):
        x_val = int(input_str, 16)
      else:
        x_val = int(input_str)

      # Kiểm tra xem có nằm trong khoảng 32-bit không (dù hàm đã mask)
      if not (0 <= x_val <= MASK_32):
          print(f"Cảnh báo: Giá trị {x_val} nằm ngoài khoảng 32-bit unsigned. Kết quả sẽ được tính dựa trên giá trị sau khi mask.")
          x_val &= MASK_32 # Mask nó lại cho chắc

      # Tính toán
      s0_result = sigma0(x_val)
      s1_result = sigma1(x_val)

      # In kết quả dạng Hexa cho dễ so sánh với Verilog
      print(f"  Giá trị nhập (đã mask 32-bit): 0x{x_val:08X}")
      print(f"  sigma0(x) = 0x{s0_result:08X}")
      print(f"  sigma1(x) = 0x{s1_result:08X}")

    except ValueError:
      print("Lỗi: Input không hợp lệ. Vui lòng nhập số nguyên hoặc hexa (0x...).")
    except Exception as e:
      print(f"Lỗi không xác định: {e}")

  print("Tạm biệt!")