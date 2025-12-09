// Candid IDL Hash Algorithm: (h * 223 + c) % 2^32

///|
pub fn idl_hash(s : String) -> UInt64 {
  let mut h : UInt64 = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = s.code_unit_at(i).to_uint64()
    h = h * 223 + c
  }
  // Moonbit UInt64 overflow wraps automatically, use bitwise operation to truncate to 32 bits
  h & 0xFFFFFFFF
}

// --- CRC32 Implementation (ISO 3309) ---

///|
const CRC32_POLY : UInt = 0xEDB88320

///|
pub fn crc32(data : Bytes) -> UInt {
  let mut crc : UInt = 0xFFFFFFFF
  for i = 0; i < data.length(); i = i + 1 {
    let byte = data[i].to_uint()
    crc = crc ^ byte
    for j = 0; j < 8; j = j + 1 {
      // Use two's complement property to construct mask
      let mask = -(crc & 1).reinterpret_as_int()
      crc = (crc >> 1) ^ (CRC32_POLY & mask.reinterpret_as_uint())
    }
  }
  crc ^ 0xFFFFFFFF
}

// Helper: convert UInt to 4-byte big-endian (Big Endian) Bytes

///|
pub fn uint_to_bytes_be(val : UInt) -> Bytes {
  let arr = FixedArray::make(4, (0).to_byte())
  arr[0] = ((val >> 24) & 0xFF).to_byte()
  arr[1] = ((val >> 16) & 0xFF).to_byte()
  arr[2] = ((val >> 8) & 0xFF).to_byte()
  arr[3] = (val & 0xFF).to_byte()
  arr.unsafe_reinterpret_as_bytes()
}

///|
pub fn bytes_to_uint_be(b : Bytes) -> UInt {
  if b.length() < 4 {
    return 0
  }
  (b[0].to_uint() << 24) |
  (b[1].to_uint() << 16) |
  (b[2].to_uint() << 8) |
  b[3].to_uint()
}

// --- Base32 Implementation (RFC 4648, no Padding, lowercase) ---

///|
const B32_ALPHABET = "abcdefghijklmnopqrstuvwxyz234567"

///|
pub fn base32_encode(data : Bytes) -> String {
  if data.length() == 0 {
    return ""
  }
  let buf = @buffer.new()
  let mut buffer : UInt = 0
  let mut bits_left = 0
  for i = 0; i < data.length(); i = i + 1 {
    buffer = (buffer << 8) | data[i].to_uint()
    bits_left = bits_left + 8
    while bits_left >= 5 {
      let index = (buffer >> (bits_left - 5)) & 0x1F
      let ch = B32_ALPHABET.code_unit_at(index.reinterpret_as_int())
      buf.write_char(ch.unsafe_to_char())
      bits_left = bits_left - 5
    }
  }
  if bits_left > 0 {
    let index = (buffer << (5 - bits_left)) & 0x1F
    let ch = B32_ALPHABET.code_unit_at(index.reinterpret_as_int())
    buf.write_char(ch.unsafe_to_char())
  }
  buf.to_string()
}

///|
pub fn base32_decode(input : String) -> Bytes raise {
  let buf = @buffer.new()
  let mut buffer : UInt = 0
  let mut bits_left = 0
  for i = 0; i < input.length(); i = i + 1 {
    let ch_code = input.code_unit_at(i)
    let ch = ch_code.unsafe_to_char()
    // Automatically skip hyphens
    if ch == '-' {
      continue
    }
    let val : UInt = match ch {
      'a'..='z' => {
        let a_code = "a".code_unit_at(0).to_uint()
        ch_code.to_uint() - a_code
      }
      '2'..='7' => {
        let two_code = "2".code_unit_at(0).to_uint()
        ch_code.to_uint() - two_code + 26
      }
      _ => fail("Invalid Base32 character: \{ch}")
    }
    buffer = (buffer << 5) | val
    bits_left = bits_left + 5
    if bits_left >= 8 {
      let byte = (buffer >> (bits_left - 8)) & 0xFF
      buf.write_byte(byte.to_byte())
      bits_left = bits_left - 8
    }
  }
  buf.to_bytes()
}
