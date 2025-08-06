// Constants
const CONTINUATION_BIT: UInt = 0x80; // 1 << 7
const SIGN_BIT: UInt = 0x40;         // 1 << 6

fn low_bits_of_u64(val: UInt) -> UInt {
	val & 0xFF & 0x7F
}

fn w_unsigned(_val: UInt) -> Bytes {
  let mut val = _val;
  let buf = @buffer.new();
  for {
	let mut byte = low_bits_of_u64(val);
	val = val >> 7;
	if val != 0 {
	  byte = byte | CONTINUATION_BIT;
	}
	  buf.write_byte(byte.to_byte());
	if val == 0 {
      break;
	}
  }
  buf.to_bytes()
}

fn w_signed(_val: Int) -> Bytes {
  let mut val = _val;
  let buf = @buffer.new();
  for {
    let mut byte = val & 0xFF;
    val = val >> 6;
    let done = val == 0 || val == -1;

    if done {
      byte = byte & 0x7F;
    } else {
      val = val >> 1;
      byte = byte | CONTINUATION_BIT.to_int();
    }
    buf.write_byte(byte.to_byte());
    if done {
      break;
    }
  }
  buf.to_bytes()
}