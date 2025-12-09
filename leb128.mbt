// Encode Unsigned LEB128

///|
pub fn leb128_encode_unsigned(val : UInt64) -> Bytes {
  let mut value = val
  let buf = @buffer.new()
  for {
    let mut byte = (value & 0x7F).to_byte()
    value = value >> 7
    if value != 0 {
      byte = byte | 0x80 // Set continuation flag
    }
    buf.write_byte(byte)
    if value == 0 {
      break
    }
  }
  buf.to_bytes()
}

// Encode Signed LEB128

///|
pub fn leb128_encode_signed(val : Int64) -> Bytes {
  let mut value = val
  let buf = @buffer.new()
  for {
    let byte_val = (value & 0x7F).to_int()
    value = value >> 7

    // Sign bit check
    let sign_bit = byte_val & 0x40
    let done = (value == 0 && sign_bit == 0) || (value == -1 && sign_bit != 0)
    let mut byte = byte_val.to_byte()
    if not(done) {
      byte = byte | 0x80 // Set continuation flag
    }
    buf.write_byte(byte)
    if done {
      break
    }
  }
  buf.to_bytes()
}
