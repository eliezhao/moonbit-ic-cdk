// Constants
const CONTINUATION_BIT: UInt = 0x80; // 1 << 7
const SIGN_BIT: UInt = 0x40;         // 1 << 6

fn unsigned(bytes: Bytes) -> UInt!String {
	let mut result: UInt = 0;
	let mut shift: UInt = 0;
	let mut i = 0;

	while i < bytes.length() {
	  let byte = bytes[i].to_int();
	  // todo: 这里没有
	  if shift == 63 && byte != 0x00 && byte != 0x01 {
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
	let mut result: Int = 0;
	let mut shift: UInt = 0;
	let mut i = 0;
	let size = 64;
	var byte: UInt = 0;

	while i < bytes.length() {
	  byte = bytes[i].to_int();
	  let low = low_bits_of_byte(byte);
	  result = result | (low.to_int() << shift.to_int());
	  shift = shift + 7;

	  if (byte & CONTINUATION_BIT) == 0 {
	    break;
	  }
	  i = i + 1;
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