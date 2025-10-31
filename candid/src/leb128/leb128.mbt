// Constants for LEB128 are defined in write.mbt
// Import them from write.mbt if needed, or remove duplicate definitions here

// Decode an unsigned LEB128 sequence to a UInt64 (up to 64-bit support)
fn leb128_decode_unsigned(bytes: Bytes) -> UInt64! {
    let mut result: UInt64 = 0;
    let mut shift: UInt = 0;         // shift (in bits) for each group of 7 bits
    let mut i: Int = 0;
    while i < bytes.length() {
        let byte = bytes[i].to_uint();       // Byte -> UInt (0..255)
        if shift == 63 && byte != 0x00 && byte != 0x01 {
            // If we've shifted 63 bits and the next byte is not 0 or 1, the number is too large (overflow for 64-bit)
            // Skip continuation bytes to find end or confirm overflow
            while i < bytes.length() && (bytes[i].to_uint() & CONTINUATION_BIT) != 0 {
                i += 1;
            }
            if i >= bytes.length() {
                fail!("Unexpected end of LEB128 input");
            }
            fail!("Unsigned LEB128 overflow");    // value needs more than 64 bits
        }
        let low: UInt64 = (byte & 0x7F).to_uint64();   // low 7 bits of byte
        result = result | (low << shift.to_int());    // accumulate 7-bit chunk
        if (byte & CONTINUATION_BIT) == 0 {
            return result;
        }
        shift += 7;
        i += 1;
    } else {  // 'while' loop optional else: if loop exits normally (no return/break)
        fail!("Unexpected end of LEB128 input");
    }
}

// Decode a signed LEB128 sequence to an Int64
fn leb128_decode_signed(bytes: Bytes) -> Int64! {
    if bytes.length() == 0 {
        fail!("LEB128 decode error: empty input");
    }
    let mut result: Int64 = 0;
    let mut shift: UInt = 0;
    let size: UInt = 64;              // total bits in target (64-bit)
    let mut i: Int = 0;
    let mut byte: UInt = 0;
    while i < bytes.length() {
        byte = bytes[i].to_uint();
        if shift == 63 && byte != 0x00 && byte != 0x7F {
            // Overflow check for signed (beyond 64 bits)
            while i < bytes.length() && (bytes[i].to_uint() & CONTINUATION_BIT) != 0 {
                i += 1;
            }
            fail!("LEB128 decode error: integer overflow");
        }
        let low = (byte & 0x7F).to_uint64();
        // Note: reinterpret as Int64 before shifting to preserve sign when combining
        result = result | (low.to_int64() << shift.to_int());
        shift += 7;
        if (byte & CONTINUATION_BIT) == 0 {
            break;
        }
        i += 1;
    }
    if (byte & CONTINUATION_BIT) != 0 {
        fail!("LEB128 decode error: truncated input");
    }
    // Sign-extend if the final byte had the sign bit set (for negative numbers)
    if shift < size && (byte & SIGN_BIT) != 0 {
        result = result | ((-1).to_int64() << shift.to_int());
    }
    return result;
}

// Encode an unsigned integer (UInt64) into LEB128 byte sequence
fn leb128_encode_unsigned(val: UInt64) -> Bytes {
    let mut value = val;
    let buf = @buffer.new();
    for {   // generate 7-bit groups
        let mut byte: UInt64 = value & 0x7F;       // take 7 bits
        value = value >> 7;
        if value != 0 {
            byte = byte | CONTINUATION_BIT.to_uint64();   // set continuation flag if more bits
        }
        buf.write_byte(byte.to_byte());
        if value == 0 {
            break;
        }
    }
    buf.to_bytes()
}

// Encode a signed integer (Int64) into LEB128 byte sequence
fn leb128_encode_signed(val: Int64) -> Bytes {
    let mut value = val;
    let buf = @buffer.new();
    for {
        let mut byte = (value & 0xFF).to_int();    // take 8 bits (will mask to 7 later)
        value = value >> 6;   // arithmetic shift by 6
        let done = (value == 0 || value == -1);
        if done {
            byte = byte & 0x7F;   // mask out continuation for last byte
        } else {
            value = value >> 1;   // total shift of 7 bits before next loop
            byte = byte | CONTINUATION_BIT.to_int();
        }
        buf.write_byte(byte.to_byte());
        if done { break; }
    }
    buf.to_bytes()
}