def ch(x, y, z):
  """Tính hàm Ch của SHA-256."""
  # Đảm bảo tính toán trên số nguyên không dấu 32-bit
  mask = 0xFFFFFFFF
  x = x & mask
  y = y & mask
  z = z & mask
  # Công thức: (x AND y) XOR ((NOT x) AND z)
  return ((x & y) ^ (~x & z)) & mask

if __name__ == "__main__":
  while True:
    try:
      x_hex = input("Nhập giá trị x (hex, ví dụ 0xAAAAAAAA): ")
      if not x_hex: break
      x_val = int(x_hex, 16)

      y_hex = input("Nhập giá trị y (hex, ví dụ 0x55555555): ")
      if not y_hex: break
      y_val = int(y_hex, 16)

      z_hex = input("Nhập giá trị z (hex, ví dụ 0xF0F0F0F0): ")
      if not z_hex: break
      z_val = int(z_hex, 16)

      # Mask lại lần nữa cho chắc
      mask32 = 0xFFFFFFFF
      x_val &= mask32
      y_val &= mask32
      z_val &= mask32

      print(f"Giá trị nhập (đã mask 32-bit):")
      print(f"  x = 0x{x_val:08x}")
      print(f"  y = 0x{y_val:08x}")
      print(f"  z = 0x{z_val:08x}")

      result_ch = ch(x_val, y_val, z_val)
      print(f"Ch(x, y, z) = 0x{result_ch:08x}")
      print("-" * 20)

    except ValueError:
      print("Lỗi: Input không phải là số hex hợp lệ.")
    except Exception as e:
      print(f"Lỗi không xác định: {e}")