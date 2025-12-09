///|
pub struct Principal {
  pub bytes : Bytes
} derive(Show, Eq)

///|
pub fn Principal::from_bytes(b : Bytes) -> Principal {
  { bytes: b }
}

///|
/// Construct Principal from Byte array
pub fn Principal::from_array(arr : Array[Byte]) -> Principal {
  let buf = @buffer.new()
  for i = 0; i < arr.length(); i = i + 1 {
    buf.write_byte(arr[i])
  }
  { bytes: buf.to_bytes() }
}

///|
/// Get anonymous Principal (User 4)
pub fn Principal::anonymous() -> Principal {
  Principal::from_bytes(@bytes.from_array([(4).to_byte()]))
}

///|
/// Get management canister Principal (empty Blob)
pub fn Principal::management_canister() -> Principal {
  Principal::from_bytes(@bytes.default())
}

///|
/// Convert to text format (e.g., "aaaaa-aa")
pub fn Principal::to_text(self : Principal) -> String {
  // 1. Calculate CRC32 (4 bytes)
  let crc = crc32(self.bytes)
  let crc_bytes = uint_to_bytes_be(crc)

  // 2. Concatenate [CRC + Bytes]
  let buf = @buffer.new()
  buf.write_bytes(crc_bytes)
  buf.write_bytes(self.bytes)

  // 3. Base32 encoding
  let b32 = base32_encode(buf.to_bytes())

  // 4. Add '-' separator (every 5 characters)
  let res = @buffer.new()
  for i = 0; i < b32.length(); i = i + 1 {
    if i > 0 && i % 5 == 0 {
      res.write_char('-')
    }
    let ch = b32.code_unit_at(i).unsafe_to_char()
    res.write_char(ch)
  }
  res.to_string()
}

///|
/// Parse Principal from text format
pub fn Principal::from_text(text : String) -> Principal raise {
  // 1. Base32 decode (automatically remove '-')
  let raw = base32_decode(text) catch { e => raise e }
  if raw.length() < 4 {
    fail("Principal text too short")
  }

  // 2. Separate CRC and Payload
  let len = raw.length()
  let crc_view = raw.sub(start=0, end=4)
  let body_view = raw.sub(start=4, end=len)

  // Convert BytesView to Bytes
  let crc_bytes = @buffer.new()
  for i = 0; i < crc_view.length(); i = i + 1 {
    crc_bytes.write_byte(crc_view[i])
  }
  let body_buf = @buffer.new()
  for i = 0; i < body_view.length(); i = i + 1 {
    body_buf.write_byte(body_view[i])
  }
  let body = body_buf.to_bytes()
  let crc_found = bytes_to_uint_be(crc_bytes.to_bytes())

  // 3. Verify CRC
  let crc_expect = crc32(body)
  if crc_found != crc_expect {
    fail("Principal CRC mismatch")
  }
  { bytes: body }
}
