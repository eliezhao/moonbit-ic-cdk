// === Encoder ===

///|
pub struct Encoder {
  buf : @buffer.Buffer
}

///|
pub fn Encoder::new() -> Encoder {
  { buf: @buffer.new() }
}

///|
pub fn Encoder::to_bytes(self : Encoder) -> Bytes {
  self.buf.to_bytes()
}

// Basic write utilities

///|
pub fn Encoder::write_bytes(self : Encoder, b : Bytes) -> Unit {
  self.buf.write_bytes(b)
}

///|
pub fn Encoder::write_byte(self : Encoder, b : Byte) -> Unit {
  self.buf.write_byte(b)
}

// LEB128 write (depends on leb128.mbt)

///|
pub fn Encoder::write_uleb128(self : Encoder, v : UInt64) -> Unit {
  self.write_bytes(leb128_encode_unsigned(v))
}

///|
pub fn Encoder::write_sleb128(self : Encoder, v : Int64) -> Unit {
  self.write_bytes(leb128_encode_signed(v))
}

// --- Candid Primitives Encoding ---

///|
/// Null: produces no bytes
pub fn Encoder::encode_null(self : Encoder) -> Unit {
  ()
}

///|
/// Reserved: produces no bytes
pub fn Encoder::encode_reserved(self : Encoder) -> Unit {
  ()
}

///|
/// Bool: 1 byte (0x01 / 0x00)
pub fn Encoder::encode_bool(self : Encoder, b : Bool) -> Unit {
  self.write_byte((if b { 1 } else { 0 }).to_byte())
}

///|
/// Nat (Arbitrary Precision): uses ULEB128 encoding
pub fn Encoder::encode_nat(self : Encoder, v : UInt64) -> Unit {
  self.write_uleb128(v)
}

///|
/// Int (Arbitrary Precision): uses SLEB128 encoding
pub fn Encoder::encode_int(self : Encoder, v : Int64) -> Unit {
  self.write_sleb128(v)
}

// --- Fixed Width Nats (Little Endian) ---

///|
pub fn Encoder::encode_nat8(self : Encoder, v : Byte) -> Unit {
  self.write_byte(v)
}

///|
pub fn Encoder::encode_nat16(self : Encoder, v : UInt16) -> Unit {
  self.write_byte((v & 0xFF).to_byte())
  self.write_byte(((v >> 8) & 0xFF).to_byte())
}

///|
pub fn Encoder::encode_nat32(self : Encoder, v : UInt) -> Unit {
  self.write_byte((v & 0xFF).to_byte())
  self.write_byte(((v >> 8) & 0xFF).to_byte())
  self.write_byte(((v >> 16) & 0xFF).to_byte())
  self.write_byte(((v >> 24) & 0xFF).to_byte())
}

///|
pub fn Encoder::encode_nat64(self : Encoder, v : UInt64) -> Unit {
  self.write_byte((v & 0xFF).to_byte())
  self.write_byte(((v >> 8) & 0xFF).to_byte())
  self.write_byte(((v >> 16) & 0xFF).to_byte())
  self.write_byte(((v >> 24) & 0xFF).to_byte())
  self.write_byte(((v >> 32) & 0xFF).to_byte())
  self.write_byte(((v >> 40) & 0xFF).to_byte())
  self.write_byte(((v >> 48) & 0xFF).to_byte())
  self.write_byte(((v >> 56) & 0xFF).to_byte())
}

// --- Fixed Width Ints (Little Endian) ---

///|
pub fn Encoder::encode_int8(self : Encoder, v : Int) -> Unit {
  // Moonbit Byte is unsigned, simple cast works for 8 bits
  self.write_byte(v.to_byte())
}

///|
pub fn Encoder::encode_int16(self : Encoder, v : Int16) -> Unit {
  let i = v.to_int()
  self.write_byte((i & 0xFF).to_byte())
  self.write_byte(((i >> 8) & 0xFF).to_byte())
}

///|
pub fn Encoder::encode_int32(self : Encoder, v : Int) -> Unit {
  // Manual bit-shift to ensure Little Endian regardless of platform
  self.write_byte((v & 0xFF).to_byte())
  self.write_byte(((v >> 8) & 0xFF).to_byte())
  self.write_byte(((v >> 16) & 0xFF).to_byte())
  self.write_byte(((v >> 24) & 0xFF).to_byte())
}

///|
pub fn Encoder::encode_int64(self : Encoder, v : Int64) -> Unit {
  // Convert to UInt64 bit pattern
  self.encode_nat64(v.reinterpret_as_uint64())
}

// --- Floats ---

///|
/// Float32 (IEEE 754 Single): convert from Double
fn f64_to_f32_bits(v : Double) -> UInt {
  let bits64 = v.reinterpret_as_uint64()
  let sign = (bits64 >> 63).to_int()
  let exp64 = ((bits64 >> 52) & 0x7FF).to_int()
  let mant64 = bits64 & 0xFFFFFFFFFFFFF

  // 1. Zero / Subnormal -> Flush to zero (simplified handling)
  if exp64 == 0 {
    return (sign << 31).to_uint()
  }

  // 2. Inf / NaN
  if exp64 == 0x7FF {
    let is_nan = mant64 != 0
    // Preserve NaN flag bit
    let mant32 = if is_nan { 0x400000 } else { 0 }
    return ((sign << 31) | (0xFF << 23) | mant32).to_uint()
  }

  // 3. Normalized
  let exp32 = exp64 - 1023 + 127
  // Underflow -> 0
  if exp32 <= 0 {
    return (sign << 31).to_uint()
  }
  // Overflow -> Inf
  if exp32 >= 255 {
    return ((sign << 31) | (0xFF << 23)).to_uint()
  }

  // Truncate mantissa (52 -> 23 bits)
  let mant32 = (mant64 >> 29).to_int()
  return ((sign << 31) | (exp32 << 23) | mant32).to_uint()
}

///|
pub fn Encoder::encode_float32(self : Encoder, v : Double) -> Unit {
  let bits = f64_to_f32_bits(v)
  self.encode_nat32(bits)
}

///|
/// Float64 (IEEE 754 Double)
pub fn Encoder::encode_float64(self : Encoder, v : Double) -> Unit {
  let bits = v.reinterpret_as_uint64()
  self.encode_nat64(bits)
}

// --- Complex Types ---

///|
pub fn Encoder::encode_text(self : Encoder, s : String) -> Unit {
  let utf8 = @encoding/utf8.encode(s)
  self.write_uleb128(utf8.length().to_uint64())
  self.write_bytes(utf8)
}

///|
pub fn Encoder::encode_blob(self : Encoder, b : Bytes) -> Unit {
  self.write_uleb128(b.length().to_uint64())
  self.write_bytes(b)
}

///|
pub fn Encoder::encode_principal(self : Encoder, p : Principal) -> Unit {
  self.write_byte((1).to_byte()) // Tag=1
  self.encode_blob(p.bytes)
}

///|
pub fn Encoder::encode_service(self : Encoder, p : Principal) -> Unit {
  self.encode_principal(p)
}

// Containers

///|
pub fn[T] Encoder::encode_opt(
  self : Encoder,
  v : T?,
  encoder : (Encoder, T) -> Unit,
) -> Unit {
  match v {
    None => self.write_byte((0).to_byte())
    Some(val) => {
      self.write_byte((1).to_byte())
      encoder(self, val)
    }
  }
}

///|
pub fn[T] Encoder::encode_vec(
  self : Encoder,
  v : Array[T],
  encoder : (Encoder, T) -> Unit,
) -> Unit {
  self.write_uleb128(v.length().to_uint64())
  for item in v {
    encoder(self, item)
  }
}

// Variant: (Index, Value)

///| Generic Variant encoding

///|
/// idx: index of the variant in the type definition
pub fn[T] Encoder::encode_variant(
  self : Encoder,
  idx : UInt64,
  val : T,
  body_encoder : (Encoder, T) -> Unit,
) -> Unit {
  self.write_uleb128(idx)
  body_encoder(self, val)
}

///| Result encoding (standard: Ok=Index 0, Err=Index 1)

///|
/// Field ordering Hash("Ok")=17724 < Hash("Err")=3456837
pub fn[T, E] Encoder::encode_result(
  self : Encoder,
  res : Result[T, E],
  ok_encoder : (Encoder, T) -> Unit,
  err_encoder : (Encoder, E) -> Unit,
) -> Unit {
  match res {
    Ok(v) => self.encode_variant(0, v, ok_encoder)
    Err(e) => self.encode_variant(1, e, err_encoder)
  }
}

// === Decoder ===

///|
pub struct Decoder {
  data : Bytes
  mut offset : Int
}

///|
pub fn Decoder::new(data : Bytes) -> Decoder {
  { data, offset: 0 }
}

///|
fn Decoder::remaining(self : Decoder) -> Int {
  self.data.length() - self.offset
}

///|
fn Decoder::read_byte(self : Decoder) -> Byte raise {
  if self.offset >= self.data.length() {
    fail("Unexpected EOF")
  }
  let b = self.data[self.offset]
  self.offset = self.offset + 1
  b
}

///|
fn Decoder::read_bytes(self : Decoder, n : Int) -> Bytes raise {
  if n < 0 {
    fail("Negative length")
  }
  if n > self.remaining() {
    fail("Unexpected EOF: declared length exceeds remaining data")
  }
  let start = self.offset
  self.offset = self.offset + n

  // Copy to new buffer
  let buf = @buffer.new(size_hint=n)
  for i = 0; i < n; i = i + 1 {
    buf.write_byte(self.data[start + i])
  }
  buf.to_bytes()
}

// LEB128 Decoding

///|
pub fn Decoder::read_uleb128(self : Decoder) -> UInt64 raise {
  let mut result : UInt64 = 0
  let mut shift = 0
  for {
    let b = self.read_byte() catch { e => raise e }
    let byte = b.to_uint()
    let low = (byte & 0x7F).to_uint64()
    result = result | (low << shift)
    if (byte & 0x80) == 0 {
      break
    }
    shift = shift + 7
    if shift > 63 {
      fail("ULEB128 overflow")
    }
  }
  result
}

///|
pub fn Decoder::read_sleb128(self : Decoder) -> Int64 raise {
  let mut result : Int64 = 0
  let mut shift = 0
  let mut byte : UInt = 0
  for {
    let b = self.read_byte() catch { e => raise e }
    byte = b.to_uint()
    let low = (byte & 0x7F).to_uint64()
    result = result | (low.reinterpret_as_int64() << shift)
    shift = shift + 7
    if (byte & 0x80) == 0 {
      break
    }
    if shift > 63 {
      fail("SLEB128 overflow")
    }
  }
  if shift < 64 && (byte & 0x40) != 0 {
    let mask = (-1).to_uint64().reinterpret_as_int64()
    result = result | (mask << shift)
  }
  result
}

// --- Primitive Decoding ---

///|
pub fn Decoder::decode_null(self : Decoder) -> Unit {
  ()
}

///|
pub fn Decoder::decode_reserved(self : Decoder) -> Unit {
  ()
}

///|
pub fn Decoder::decode_bool(self : Decoder) -> Bool raise {
  let b = self.read_byte() catch { e => raise e }
  if b == (0).to_byte() {
    false
  } else if b == (1).to_byte() {
    true
  } else {
    fail("Invalid bool byte")
  }
}

///|
pub fn Decoder::decode_nat(self : Decoder) -> UInt64 raise {
  self.read_uleb128() catch {
    e => raise e
  }
}

///|
pub fn Decoder::decode_int(self : Decoder) -> Int64 raise {
  self.read_sleb128() catch {
    e => raise e
  }
}

// Fixed Width Nats

///|
pub fn Decoder::decode_nat8(self : Decoder) -> Byte raise {
  self.read_byte() catch {
    e => raise e
  }
}

///|
pub fn Decoder::decode_nat16(self : Decoder) -> UInt16 raise {
  let b0 = (self.read_byte() catch { e => raise e }).to_uint16()
  let b1 = (self.read_byte() catch { e => raise e }).to_uint16()
  b0 | (b1 << 8)
}

///|
pub fn Decoder::decode_nat32(self : Decoder) -> UInt raise {
  let b0 = (self.read_byte() catch { e => raise e }).to_uint()
  let b1 = (self.read_byte() catch { e => raise e }).to_uint()
  let b2 = (self.read_byte() catch { e => raise e }).to_uint()
  let b3 = (self.read_byte() catch { e => raise e }).to_uint()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
pub fn Decoder::decode_nat64(self : Decoder) -> UInt64 raise {
  let b0 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b1 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b2 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b3 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b4 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b5 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b6 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  let b7 = (self.read_byte() catch { e => raise e }).to_uint().to_uint64()
  b0 |
  (b1 << 8) |
  (b2 << 16) |
  (b3 << 24) |
  (b4 << 32) |
  (b5 << 40) |
  (b6 << 48) |
  (b7 << 56)
}

// Fixed Width Ints

///|
pub fn Decoder::decode_int8(self : Decoder) -> Int raise {
  let b = (self.read_byte() catch { e => raise e }).to_int()
  // Sign extension (8-bit to 32-bit)
  // If bit 7 is set (b & 0x80), we OR with 0xFFFFFF00 (-256)
  if (b & 0x80) != 0 {
    b | -256
  } else {
    b
  }
}

///|
pub fn Decoder::decode_int16(self : Decoder) -> Int16 raise {
  let u = (self.decode_nat16() catch { e => raise e }).to_int()
  // 16-bit Sign extension
  let signed_int = if (u & 0x8000) != 0 { u | 0xFFFF0000 } else { u }
  signed_int.to_int16()
}

///|
pub fn Decoder::decode_int32(self : Decoder) -> Int raise {
  let u = self.decode_nat32() catch { e => raise e }
  u.to_int() // Bitwise reinterpretation to signed Int
}

///|
pub fn Decoder::decode_int64(self : Decoder) -> Int64 raise {
  let u = self.decode_nat64() catch { e => raise e }
  u.reinterpret_as_int64()
}

// Floats

///|
fn f32_bits_to_f64(bits : UInt) -> Double {
  let sign = (bits >> 31).to_int64()
  let exp32 = ((bits >> 23) & 0xFF).to_int()
  let mant32 = (bits & 0x7FFFFF).to_uint64()
  if exp32 == 0 {
    return 0.0
  }
  if exp32 == 255 {
    return if mant32 == 0 { 1.0 / 0.0 } else { 0.0 / 0.0 }
  }
  let exp64 = exp32 - 127 + 1023
  let mant64 = mant32 << 29
  let bits64 = (sign.reinterpret_as_uint64() << 63) |
    (exp64.to_uint64() << 52) |
    mant64
  bits64.reinterpret_as_double()
}

///|
pub fn Decoder::decode_float32(self : Decoder) -> Double raise {
  let bits = self.decode_nat32() catch { e => raise e }
  f32_bits_to_f64(bits)
}

///|
pub fn Decoder::decode_float64(self : Decoder) -> Double raise {
  let u = self.decode_nat64() catch { e => raise e }
  u.reinterpret_as_double()
}

// Complex Types

///|
pub fn Decoder::decode_text(self : Decoder) -> String raise {
  let len = (self.read_uleb128() catch { e => raise e }).to_int()
  let bytes = self.read_bytes(len) catch { e => raise e }
  @encoding/utf8.decode(bytes) catch {
    e => raise e
  }
}

///|
pub fn Decoder::decode_blob(self : Decoder) -> Bytes raise {
  let len = (self.read_uleb128() catch { e => raise e }).to_int()
  self.read_bytes(len) catch {
    e => raise e
  }
}

///|
pub fn Decoder::decode_principal(self : Decoder) -> Principal raise {
  let tag = self.read_byte() catch { e => raise e }
  if tag != (1).to_byte() {
    fail("Principal tag must be 1")
  }
  let bytes = self.decode_blob() catch { e => raise e }
  Principal::from_bytes(bytes)
}

///|
pub fn Decoder::decode_service(self : Decoder) -> Principal raise {
  self.decode_principal() catch {
    e => raise e
  }
}

///|
pub fn[T] Decoder::decode_opt(
  self : Decoder,
  decoder : (Decoder) -> T raise,
) -> T? raise {
  let tag = self.read_byte() catch { e => raise e }
  match tag.to_int() {
    0 => None
    1 => Some(decoder(self) catch { e => raise e })
    _ => fail("Invalid option tag")
  }
}

///|
pub fn[T] Decoder::decode_vec(
  self : Decoder,
  decoder : (Decoder) -> T raise,
) -> Array[T] raise {
  let len = (self.read_uleb128() catch { e => raise e }).to_int()

  // 1. Hard limit: prevent cycle exhaustion (e.g., 4 billion nulls)
  if len > 10000000 {
    fail("Vector length too large (DoS protection)")
  }

  // 2. Soft limit: if declared length > remaining bytes, it's definitely fake (assuming at least 1 byte per element)
  // For special cases like vec null, the hard limit above will take effect
  if len > self.remaining() {
    fail("Vector length exceeds remaining bytes")
  }
  let arr = []
  for i = 0; i < len; i = i + 1 {
    arr.push(decoder(self) catch { e => raise e })
  }
  arr
}

// Variant & Result

///|
pub fn Decoder::decode_variant_index(self : Decoder) -> UInt64 raise {
  self.read_uleb128() catch {
    e => raise e
  }
}

///|
pub fn[T, E] Decoder::decode_result(
  self : Decoder,
  ok_decoder : (Decoder) -> T raise,
  err_decoder : (Decoder) -> E raise,
) -> Result[T, E] raise {
  let idx = self.decode_variant_index() catch { e => raise e }
  match idx {
    0 => Ok(ok_decoder(self) catch { e => raise e })
    1 => Err(err_decoder(self) catch { e => raise e })
    _ => fail("Invalid Result index (expected 0 or 1)")
  }
}

// Skip Type Table (for parsing real requests)

///|
pub fn Decoder::skip_type_table(self : Decoder) -> Unit raise {
  let table_count = (self.read_uleb128() catch { e => raise e }).to_int()
  for i = 0; i < table_count; i = i + 1 {
    let opcode = self.read_sleb128() catch { e => raise e }
    if opcode >= 0 {
      continue
    }
    match opcode {
      TYPE_OPT | TYPE_VEC => {
        let _ = self.read_sleb128() catch { e => raise e }

      }
      TYPE_RECORD | TYPE_VARIANT => {
        let field_cnt = (self.read_uleb128() catch { e => raise e }).to_int()
        for j = 0; j < field_cnt; j = j + 1 {
          let _ = self.read_uleb128() catch { e => raise e }
          let _ = self.read_sleb128() catch { e => raise e }

        }
      }
      TYPE_FUNC => {
        let args = (self.read_uleb128() catch { e => raise e }).to_int()
        for k = 0; k < args; k = k + 1 {
          let _ = self.read_sleb128() catch { e => raise e }

        }
        let rets = (self.read_uleb128() catch { e => raise e }).to_int()
        for k = 0; k < rets; k = k + 1 {
          let _ = self.read_sleb128() catch { e => raise e }

        }
        let modes_len = (self.read_uleb128() catch { e => raise e }).to_int()
        let _ = self.read_bytes(modes_len) catch { e => raise e }

      }
      TYPE_SERVICE => {
        let meths = (self.read_uleb128() catch { e => raise e }).to_int()
        for k = 0; k < meths; k = k + 1 {
          let name_len = (self.read_uleb128() catch { e => raise e }).to_int()
          let _ = self.read_bytes(name_len) catch { e => raise e }
          let _ = self.read_sleb128() catch { e => raise e }

        }
      }
      _ => ()
    }
  }
}

// src/ic_candid/candid_codec.mbt

///| Encode complete DIDL message with single return value (automatically adds header)

///| type_opcode: Candid Opcode of the type (e.g., TYPE_TEXT = -15, TYPE_PRINCIPAL = -24)

///|
/// encoder: encoding function for the value
pub fn[T] encode_one(
  val : T,
  type_opcode : Int64,
  encoder : (Encoder, T) -> Unit,
) -> Bytes {
  let enc = Encoder::new()

  // 1. Magic Header "DIDL"
  enc.write_bytes(@encoding/utf8.encode("DIDL"))

  // 2. Type Table Length (0 means no complex type definitions)
  enc.write_uleb128(0)

  // 3. Arguments Count (1 return value)
  enc.write_uleb128(1)

  // 4. Argument Type
  enc.write_sleb128(type_opcode)

  // 5. Value Encoding
  encoder(enc, val)
  enc.to_bytes()
}
