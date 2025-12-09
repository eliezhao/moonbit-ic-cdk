///|
fn main {
  println("=== Moonbit IC Candid Demo ===")

  // 1. [Simulate business] Construct a response
  let response : @lib.HttpResponse = {
    status_code: 404,
    headers: [("X-Powered-By", "Moonbit"), ("Content-Type", "text/plain")],
    body: @encoding/utf8.encode("Resource Not Found"),
    upgrade: None,
    streaming_strategy: None,
  }

  // 2. [Encoding] Convert response to Bytes
  println("[1] Encoding HttpResponse...")
  let output_bytes = @lib.encode_http_response(response)
  println("    Encoded size: \{output_bytes.length()} bytes")

  // 3. [Output] Print Hex string (for verification)
  let hex_str = bytes_to_hex(output_bytes)
  println("    Hex: \{hex_str}")

  // 4. [Decoding] Verify decoder (simulate receiving standard binary data)
  println("[2] Decoding HttpRequest (Simulated)...")

  // Here constructs a standard-compliant Request packet: 
  // GET /index.html, body=empty, headers=[]
  // (DIDL + Empty Table + Empty Types + Values)
  // This is the simplest legal packet for integration testing
  let raw_request_hex = "4449444C00000B2F696E6465782E68746D6C034745540000"
  let raw_input = hex_to_bytes(raw_request_hex)
  try {
    let req = @lib.decode_http_request(raw_input)
    println("    Success!")
    println("    Method: \{req.method}")
    println("    URL:    \{req.url}")
  } catch {
    @lib.DecodeError(e) => println("    Decode Error: \{e}")
  }
}

// --- Helper Utility Functions ---

///|
fn bytes_to_hex(bytes : Bytes) -> String {
  let hex_chars = "0123456789ABCDEF"
  let result = StringBuilder::new()
  for i = 0; i < bytes.length(); i = i + 1 {
    let b = bytes[i].to_int()
    let high = (b >> 4) & 0xF
    let low = b & 0xF
    result.write_char(hex_chars.unsafe_charcode_at(high).unsafe_to_char())
    result.write_char(hex_chars.unsafe_charcode_at(low).unsafe_to_char())
  }
  result.to_string()
}

///|
fn hex_to_bytes(hex : String) -> Bytes {
  let len = hex.length() / 2
  let buf = @buffer.new(size_hint=len)
  for i = 0; i < len; i = i + 1 {
    let h = parse_hex(hex.unsafe_charcode_at(i * 2).unsafe_to_char())
    let l = parse_hex(hex.unsafe_charcode_at(i * 2 + 1).unsafe_to_char())
    buf.write_byte(((h << 4) | l).to_byte())
  }
  buf.to_bytes()
}

///|
fn parse_hex(c : Char) -> Int {
  let code = c.to_int()
  if code >= '0'.to_int() && code <= '9'.to_int() {
    code - '0'.to_int()
  } else if code >= 'A'.to_int() && code <= 'F'.to_int() {
    code - 'A'.to_int() + 10
  } else if code >= 'a'.to_int() && code <= 'f'.to_int() {
    code - 'a'.to_int() + 10
  } else {
    0
  }
}
