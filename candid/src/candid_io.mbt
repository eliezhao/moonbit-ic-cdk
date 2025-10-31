// Import the LEB128 helpers and type definitions

// example usage:
// Example usage: If we want to encode a Result<Int, Text> (i.e. Result<Int, String] in MoonBit) where Int is a 32-bit integer and Text is a string:
// let r: Result[Int, String] = Ok(42);
// let bytes = encode_result[Int, String](r, 
    // fn(v: Int) -> Bytes { encode_int32(v) },         // use 32-bit int encoder
    // fn(e: String) -> Bytes { encode_text(e) }
// );
// `bytes` now holds the Candid binary encoding of an Ok(42) value of type `Result<int32, text>`

// Decoding it back:
// let decoded: Result[Int, String] = decode_result[Int, String](bytes,
//     fn(b: Bytes) -> Int! { decode_int32(b) },
//     fn(b: Bytes) -> String! { decode_text(b) }
// )!;


import "leb128/leb128.mbt"
import "candid_types.mbt"

// Encoding functions

fn encode_bool(b: Bool) -> Bytes {
    // Bool: 0x01 for true, 0x00 for false
    let byteVal = if b { 0x01 } else { 0x00 };
    // Return as single-byte sequence
    [ byteVal.to_byte() ].to_bytes()    // construct Bytes from a single Byte value
}

fn encode_int(val: Int64) -> Bytes {
    // Encode a signed integer (64-bit) as Candid int (SLEB128)
    leb128_encode_signed(val)
}

fn encode_nat(val: UInt64) -> Bytes {
    // Encode an unsigned integer (64-bit) as Candid nat (ULEB128)
    leb128_encode_unsigned(val)
}

// Fixed-size integer encoding (little-endian)
fn encode_int32(val: Int) -> Bytes {
    // Int is 32-bit in MoonBit. We'll output 4 bytes little-endian.
    let buf = @buffer.new();
    buf.write_byte((val        & 0xFF).to_byte());
    buf.write_byte(((val >> 8) & 0xFF).to_byte());
    buf.write_byte(((val >> 16) & 0xFF).to_byte());
    buf.write_byte(((val >> 24) & 0xFF).to_byte());
    buf.to_bytes()
}
fn encode_int16(val: Int16) -> Bytes {
    let buf = @buffer.new();
    buf.write_byte((val        & 0xFF).to_byte());
    buf.write_byte(((val >> 8) & 0xFF).to_byte());
    buf.to_bytes()
}
// (Similarly, encode_int64 would output 8 bytes little-endian, but we typically use leb128 for generic int unless the type is specifically int64.)

fn encode_nat32(val: UInt) -> Bytes {
    // 32-bit unsigned
    let buf = @buffer.new();
    buf.write_byte((val        & 0xFF).to_byte());
    buf.write_byte(((val >> 8) & 0xFF).to_byte());
    buf.write_byte(((val >> 16) & 0xFF).to_byte());
    buf.write_byte(((val >> 24) & 0xFF).to_byte());
    buf.to_bytes()
}
fn encode_nat16(val: UInt16) -> Bytes {
    let buf = @buffer.new();
    buf.write_byte((val        & 0xFF).to_byte());
    buf.write_byte(((val >> 8) & 0xFF).to_byte());
    buf.to_bytes()
}

// Float encoding (IEEE-754). We'll assume MoonBit Float/Double can be bit-cast or written via buffer.
fn encode_float32(f: Float) -> Bytes {
    let buf = @buffer.new();
    buf.write_float(f);    // (Assuming buffer has method to write 32-bit float in LE)
    buf.to_bytes()
}
fn encode_float64(d: Double) -> Bytes {
    let buf = @buffer.new();
    buf.write_double(d);   // (Assuming buffer can write 64-bit double in LE)
    buf.to_bytes()
}

fn encode_text(s: String) -> Bytes {
    // Encode string as candid text: LEB128 length followed by UTF-8 bytes
    let utf8: Bytes = s.to_utf8();              // MoonBit String -> Bytes (UTF8)
    let len: UInt64 = utf8.length().to_uint64();
    let mut out = leb128_encode_unsigned(len);
    out = out.concat(utf8);
    out
}

fn encode_blob(blob: Bytes) -> Bytes {
    // Blob is just vec nat8: encode length then raw bytes
    let len = blob.length().to_uint64();
    let mut out = leb128_encode_unsigned(len);
    out = out.concat(blob);
    out
}

fn encode_principal(p: Principal) -> Bytes {
    // Principal: length (ULEB128) + bytes
    let len = p.bytes.length().to_uint64();
    var out = leb128_encode_unsigned(len);
    out = out.concat(p.bytes);
    out
}

// Option<T>: 0x00 for None, 0x01 + encode T for Some
fn encode_option[T](opt: Option[T], encode_elem: fn (T) -> Bytes) -> Bytes {
    match opt {
        None    => [0x00.to_byte()].to_bytes(),
        Some(x) => {
            let mut out = [0x01.to_byte()].to_bytes();
            out = out.concat(encode_elem(x));
            out
        }
    }
}

// Result<T,E>: encode as variant { Ok; Err } 
// Ok -> tag 0, Err -> tag 1, followed by value encoding
fn encode_result[T, E](res: Result[T, E], encode_t: fn(T) -> Bytes, encode_e: fn(E) -> Bytes) -> Bytes {
    let buf = @buffer.new();
    match res {
        Ok(v) => {
            // tag 0 for Ok
            buf.write_byte(0x00.to_byte());
            let valBytes = encode_t(v);
            buf.write_bytes(valBytes);
        }
        Err(e) => {
            // tag 1 for Err
            buf.write_byte(0x01.to_byte());
            let errBytes = encode_e(e);
            buf.write_bytes(errBytes);
        }
    }
    buf.to_bytes()
}

// Decoding functions (inverse of above encoders)

fn decode_bool(data: Bytes) -> Bool! {
    if data.length() < 1 { fail!("decode_bool: no input") }
    let b = data[0].to_uint();
    match b {
      0x00 => false,
      0x01 => true,
      _    => fail!("Invalid boolean value")
    }
}

fn decode_int(data: Bytes) -> Int64! {
    leb128_decode_signed(data)
}
fn decode_nat(data: Bytes) -> UInt64! {
    leb128_decode_unsigned(data)
}

// Decode fixed-size ints from little-endian bytes
fn decode_int32(data: Bytes) -> Int! {
    if data.length() < 4 { fail!("decode_int32: input too short") }
    var u: UInt = 0;
    u = u | data[0].to_uint();
    u = u | (data[1].to_uint() << 8);
    u = u | (data[2].to_uint() << 16);
    u = u | (data[3].to_uint() << 24);
    // Interpret as signed 32-bit:
    let i: Int = u.to_int();   // reinterpret lower 32 bits as Int
    i
}
fn decode_int16(data: Bytes) -> Int16! {
    if data.length() < 2 { fail!("decode_int16: input too short") }
    var u: UInt16 = 0;
    u = u | data[0].to_uint16();
    u = u | ((data[1].to_uint16()) << 8);
    let i: Int16 = u.to_int16();
    i
}

fn decode_text(data: Bytes) -> String! {
    // Read length (ULEB128), then that many bytes as UTF8 string
    let len = leb128_decode_unsigned(data)!;
    let startIdx = leb128_encode_unsigned(len).length();  // length of length field
    if data.length() < startIdx + len.to_uint() {
        fail!("decode_text: input shorter than indicated length")
    }
    let textBytes = data.slice(startIdx.to_int(), (startIdx + len.to_uint()).to_int());
    String.from_utf8(textBytes)!      // convert UTF8 bytes to MoonBit String
}

fn decode_blob(data: Bytes) -> Bytes! {
    // Similar to text: first field is length
    let len = leb128_decode_unsigned(data)!;
    let headerLen = leb128_encode_unsigned(len).length();
    if data.length() < headerLen + len.to_uint() {
        fail!("decode_blob: input shorter than indicated length")
    }
    data.slice(headerLen.to_int(), (headerLen + len.to_uint()).to_int())
}

fn decode_principal(data: Bytes) -> Principal! {
    let len = leb128_decode_unsigned(data)!;
    let headerLen = leb128_encode_unsigned(len).length();
    if data.length() < headerLen + len.to_uint() {
        fail!("decode_principal: input too short")
    }
    let bytes = data.slice(headerLen.to_int(), (headerLen + len.to_uint()).to_int());
    Principal::from_bytes(bytes)
}

fn decode_option[T](data: Bytes, decode_elem: fn(Bytes) -> T!) -> Option[T]! {
    if data.length() == 0 { fail!("decode_option: no input") }
    let tag = data[0].to_uint();
    if tag == 0x00 {
        // None
        return None;
    } else if tag == 0x01 {
        // Some – decode the rest as the inner value
        let innerBytes = data.slice(1, data.length().to_int());
        let value = decode_elem(innerBytes)!;
        return Some(value);
    } else {
        fail!("decode_option: invalid tag");
    }
}

fn decode_result[T, E](data: Bytes, decode_t: fn(Bytes) -> T!, decode_e: fn(Bytes) -> E!) -> Result[T, E]! {
    if data.length() == 0 { fail!("decode_result: no input") }
    let tag = data[0].to_uint();
    let rest = data.slice(1, data.length().to_int());
    if tag == 0x00 {
        // Ok variant
        let value = decode_t(rest)!;
        return Ok(value);
    } else if tag == 0x01 {
        // Err variant
        let err = decode_e(rest)!;
        return Err(err);
    } else {
        fail!("decode_result: invalid variant tag");
    }
}