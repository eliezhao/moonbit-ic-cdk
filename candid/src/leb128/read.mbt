// Constants
const MAX_BYTES: UInt = 10   // 最多 10 字节

fn r_unsigned(bytes: Bytes) -> UInt! {
  let mut result: UInt = 0
  let mut shift: UInt = 0
  let mut i = 0

  while i < bytes.length() {
    let byte = bytes[i].to_uint()
  if shift == 63 && byte != 0x00 && byte != 0x01 {
    let mut j = i
	while (j < bytes.length() && (bytes[j].to_uint() & CONTINUATION_BIT) != 0) {
	  j += 1
    }
    if (j >= bytes.length()) {
	  fail!("Unexpected end of LEB128 input")
    }
    fail!("Unsigned LEB128 overflow")
  }


  let low : UInt = low_bits_of_byte(byte)
  result = result | (low << shift.to_int())

  if (byte & CONTINUATION_BIT) == 0 {
    return result
  }
    shift = shift + 7
    i = i + 1
  } else {
    fail!("Unexpected end of LEB128 input")
  }
}

fn r_signed(bytes: Bytes) -> Int! {
  if bytes.length() == 0 {
	fail!("LEB128 decode error: empty input".to_string())
  }

  let mut result: Int = 0
  let mut shift: UInt = 0
  let mut i = 0
  let size : UInt = 64
  let mut byte: UInt = 0

  while i < bytes.length() {
	byte = bytes[i].to_uint()
	if shift == 63 && byte != 0x00 && byte != 0x7F {
	  while i < bytes.length() && (bytes[i].to_uint() & CONTINUATION_BIT) != 0 {
	    i = i + 1
      }
	  fail!("LEB128 decode error: integer overflow".to_string())
    }

    let low = low_bits_of_byte(byte)
    result = result | (low.reinterpret_as_int() << shift.reinterpret_as_int())
    shift = shift + 7

    if(byte & CONTINUATION_BIT) == 0 {
      break
    }
    i = i + 1
  }

  if (byte & CONTINUATION_BIT) != 0 {
    fail!("LEB128 decode error: truncated input".to_string())
  }

  if shift < size && (byte & SIGN_BIT) != 0 {
    result = result | (-1 << shift.reinterpret_as_int())
  }

  return result
}


fn low_bits_of_byte(b: UInt) -> UInt {
  b & 0x7F
}