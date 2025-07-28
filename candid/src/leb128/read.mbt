// 1. 整理逻辑
// 2. 修正语法
// 3. 封装函数

// Constants
const CONTINUATION_BIT: UInt = 0x80; // 1 << 7
const SIGN_BIT: UInt = 0x40;         // 1 << 6
const MAX_BYTES: UInt = 10;   // 最多 10 字节


fn unsigned(bytes: Bytes) -> UInt!String {
	let mut result: UInt = 0;
	let mut shift: UInt = 0;
	let mut i = 0;

	while i < bytes.length() {
	  let byte = bytes[i].to_int();
	  if shift == 63 && byte != 0x00 && byte != 0x01 {
	    let mut j = i;
	    while (j < bytes.length() && (bytes[j].to_int() & CONTINUATION_BIT) != 0) {
	      j += 1;
	    }
	    if (j >= bytes.length()) {
	      return raise("Unexpected end of LEB128 input");
	    }
	    return raise("Unsigned LEB128 overflow");
	  }

	  let low = low_bits_of_byte(byte);
	  result = result | (low << shift);

	  if (byte & CONTINUATION_BIT) == 0 {
	    return result;
	  }
	  shift = shift + 7;
	  i = i + 1;
	}
	raise("Unexpected end of LEB128 input")
}

fn signed(bytes: Bytes) -> Int!String {
    if bytes.length() == 0 {
      return Err("LEB128 decode error: empty input".to_string());
    }

	let mut result: Int = 0;
	let mut shift: UInt = 0;
	let mut i = 0;
	let size = 64;
	let mut byte: UInt = 0;

	while i < bytes.length() {
	  byte = bytes[i].to_int();
	  if shift == 63 && byte != 0x00 && byte != 0x7F {
	    while i < bytes.length() && (bytes[i].to_int() & CONTINUATION_BIT) != 0 {
	        i = i + 1;
	    }
	    return Err("LEB128 decode error: integer overflow".to_string());
	  }

	  let low = low_bits_of_byte(byte);
	  result = result | (low.to_int() << shift.to_int());
	  shift = shift + 7;

	  if (byte & CONTINUATION_BIT) == 0 {
	    break;
	  }
	  i = i + 1;
	}

   if (byte & CONTINUATION_BIT) != 0 {
      return Err("LEB128 decode error: truncated input".to_string());
    }

	if shift < size && (byte & SIGN_BIT) != 0 {
	  result = result | (-1 << shift.to_int());
	}

	return result;
}

fn low_bits_of_byte(b: UInt) -> UInt {
	b & 0x7F
}

test "leb128 test" {


}