// Constants
const CONTINUATION_BIT: UInt = 0x80; // 1 << 7
const SIGN_BIT: UInt = 0x40;         // 1 << 6

fn low_bits_of_u64(val: UInt) -> UInt {
	val & 0xFF & 0x7F
}

fn unsigned(mut val: UInt) -> Bytes {
	let buf = @buffer.new();
	loop {
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

fn signed(mut val: Int) -> Bytes {
	let buf = @buffer.new();
	loop {
		let mut byte = val.to_int() & 0xFF;
		let sign_bit = byte & SIGN_BIT;
		val = val >> 6;
		let done = val == 0 || val == -1;

		if done {
			byte = byte & 0x7F;
		} else {
			val = val >> 1;
			byte = byte | CONTINUATION_BIT;
		}
			buf.write_byte(byte.to_byte());
		if done {
			break;
		}
	}
	buf.to_bytes()
}
