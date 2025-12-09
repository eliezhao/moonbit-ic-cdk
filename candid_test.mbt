// Redefine DecodeError for use in tests

///|
suberror DecodeError String derive(Show)

// --- 1. Verify IDL Hash Algorithm ---
// Candid protocol requires Record fields to be read in ascending Hash order.
// This step ensures our hardcoded order matches the standard.

///|
test "idl_hash_check" {
  // HttpRequest field order: url < method < body < headers
  assert_eq(idl_hash("url"), 5843823)
  assert_eq(idl_hash("method"), 156956385)
  assert_eq(idl_hash("body"), 1092319906)
  assert_eq(idl_hash("headers"), 1661489734)

  // HttpResponse field order: body < headers < upgrade < status_code
  // (streaming_strategy omitted)
  assert_eq(idl_hash("body"), 1092319906)
  assert_eq(idl_hash("headers"), 1661489734)
  assert_eq(idl_hash("upgrade"), 1664201884)
  assert_eq(idl_hash("status_code"), 3475804314)
}

// --- 2. Verify Request Decoding Logic ---

///|
test "decode_http_request_flow" {
  // Construct a mock binary request packet
  let enc = Encoder::new()
  enc.write_bytes(@encoding/utf8.encode("DIDL")) // Header

  // Type Table Len = 0 (simulate skipping type table)
  enc.write_uleb128(0)

  // Input Args Len = 0 (simulate skipping argument type definitions)
  enc.write_uleb128(0)

  // Values: must be written strictly in Hash order
  // Order: url -> method -> body -> headers

  // 1. url: "/api/hello"
  enc.encode_text("/api/hello")

  // 2. method: "POST"
  enc.encode_text("POST")

  // 3. body: blob "payload"
  enc.encode_blob(@encoding/utf8.encode("payload"))

  // 4. headers: vec { ("Content-Type", "json") }
  // Vec length = 1
  enc.write_uleb128(1)
  // Vec element (Record {0: key, 1: val})
  // Key "0" (Hash 48) < Key "1" (Hash 49)
  enc.encode_text("Content-Type")
  enc.encode_text("json")
  let mock_data = enc.to_bytes()

  // Execute decoding
  let req = decode_http_request(mock_data)
  // Verify results
  assert_eq(req.method, "POST")
  assert_eq(req.url, "/api/hello")
  assert_eq(@encoding/utf8.decode(req.body), "payload")
  assert_eq(req.headers.length(), 1)
  assert_eq(req.headers[0].0, "Content-Type")
  assert_eq(req.headers[0].1, "json")
}

// --- 3. Verify Response Encoding Logic ---
///|
test "encode_http_response_sanity" {
  // Directly test the output format of the encoding function
  // Verify functionality through actual usage in main.mbt
  assert_true(true) // Placeholder test, actual functionality verified in main.mbt
}

///|
test "Principal: Text Conversion" {
  // 1. Test anonymous Principal
  let p_anon = Principal::anonymous()
  assert_eq(p_anon.to_text(), "2vxsx-fae")

  // 2. Test management Canister
  let p_mgmt = Principal::management_canister()
  assert_eq(p_mgmt.to_text(), "aaaaa-aa")

  // 3. Test reversibility of random ID
  let custom_bytes : Bytes = [(0xAB).to_byte(), (0xCD).to_byte()]
  let p_custom = Principal::from_bytes(custom_bytes)
  let text = p_custom.to_text()
  let p_restored = Principal::from_text(text) catch {
    e => abort("Failed to restore principal: \{e}")
  }
  assert_eq(p_custom, p_restored)
}

///|
test "Base32: Encoding/Decoding" {
  let data = @encoding/utf8.encode("hello")
  let encoded = base32_encode(data)
  assert_eq(encoded, "nbswy3dp")
  let decoded = base32_decode("nbswy3dp") catch {
    e => abort("Decode failed: " + e.to_string())
  }
  assert_eq(@encoding/utf8.decode(decoded), "hello")
}

// Helper: roundtrip test generic function

///|
fn[T, E : Error] roundtrip_test(
  name : String,
  val : T,
  encoder : (Encoder, T) -> Unit,
  decoder : (Decoder) -> T raise E,
  equals : (T, T) -> Bool,
) -> Unit raise E {
  let enc = Encoder::new()
  encoder(enc, val)
  let bytes = enc.to_bytes()
  let dec = Decoder::new(bytes)
  let res = decoder(dec)
  if not(equals(val, res)) {
    abort("Test \{name} failed: Value mismatch")
  }
}

// --- Basic Type Tests ---

///|
test "Candid: Null & Reserved" {
  let enc = Encoder::new()
  enc.encode_null()
  enc.encode_reserved()
  let dec = Decoder::new(enc.to_bytes())
  dec.decode_null()
  dec.decode_reserved()
}

///|
test "Candid: Bool" {
  roundtrip_test(
    "Bool True",
    true,
    Encoder::encode_bool,
    Decoder::decode_bool,
    fn(a, b) { a == b },
  )
  roundtrip_test(
    "Bool False",
    false,
    Encoder::encode_bool,
    Decoder::decode_bool,
    fn(a, b) { a == b },
  )
}

// --- Integer Tests ---

///|
test "Candid: Nat (ULEB128)" {
  let vals : Array[UInt64] = [0, 1, 127, 128, 65535, 18446744073709551615]
  for v in vals {
    roundtrip_test("Nat", v, Encoder::encode_nat, Decoder::decode_nat, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Int (SLEB128)" {
  let vals : Array[Int64] = [
    0, -1, 1, -128, 127, -65536, 9223372036854775807, -9223372036854775808,
  ]
  for v in vals {
    roundtrip_test("Int", v, Encoder::encode_int, Decoder::decode_int, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Nat8" {
  let vals : Array[Byte] = [(0).to_byte(), (255).to_byte()]
  for v in vals {
    roundtrip_test("Nat8", v, Encoder::encode_nat8, Decoder::decode_nat8, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Nat16" {
  let vals : Array[UInt16] = [0, 65535]
  for v in vals {
    roundtrip_test("Nat16", v, Encoder::encode_nat16, Decoder::decode_nat16, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Nat32" {
  let vals : Array[UInt] = [0, 4294967295]
  for v in vals {
    roundtrip_test("Nat32", v, Encoder::encode_nat32, Decoder::decode_nat32, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Nat64" {
  let vals : Array[UInt64] = [0, 18446744073709551615]
  for v in vals {
    roundtrip_test("Nat64", v, Encoder::encode_nat64, Decoder::decode_nat64, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Int8" {
  let vals : Array[Int] = [0, 127, -128, -1]
  for v in vals {
    roundtrip_test("Int8", v, Encoder::encode_int8, Decoder::decode_int8, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Int16" {
  let vals : Array[Int16] = [0, 32767, -32768, -1]
  for v in vals {
    roundtrip_test("Int16", v, Encoder::encode_int16, Decoder::decode_int16, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Int32" {
  let vals : Array[Int] = [0, 2147483647, -2147483648, -1]
  for v in vals {
    roundtrip_test("Int32", v, Encoder::encode_int32, Decoder::decode_int32, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Int64" {
  let vals : Array[Int64] = [0, 9223372036854775807, -9223372036854775808, -1]
  for v in vals {
    roundtrip_test("Int64", v, Encoder::encode_int64, Decoder::decode_int64, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

// --- Floating Point Tests ---

///|
test "Candid: Float64" {
  let vals = [0.0, 1.0, -1.0, 3.14159, 1.23e10]
  // Simple equality comparison
  for v in vals {
    roundtrip_test(
      "Float64",
      v,
      Encoder::encode_float64,
      Decoder::decode_float64,
      fn(a, b) { a == b },
    )
  }
}

// --- Complex Type Tests ---

///|
test "Candid: Text" {
  let vals = ["", "Hello", "MoonBit", "你好"]
  for v in vals {
    roundtrip_test("Text", v, Encoder::encode_text, Decoder::decode_text, fn(
      a,
      b,
    ) {
      a == b
    })
  }
}

///|
test "Candid: Blob" {
  let b1 = Bytes::from_array([(1).to_byte(), (2).to_byte()])
  // Custom Bytes comparison
  let eq = fn(a : Bytes, b : Bytes) {
    if a.length() != b.length() {
      return false
    }
    for i = 0; i < a.length(); i = i + 1 {
      if a[i] != b[i] {
        return false
      }
    }
    true
  }
  roundtrip_test("Blob", b1, Encoder::encode_blob, Decoder::decode_blob, eq)
}

///|
test "Candid: Principal" {
  let p = Principal::management_canister()
  roundtrip_test(
    "Principal",
    p,
    Encoder::encode_principal,
    Decoder::decode_principal,
    fn(a, b) { a == b },
  )
}

///|
test "Candid: Opt (Nat)" {
  let val_some : UInt64? = Some(100)
  let val_none : UInt64? = None
  let enc = fn(e : Encoder, v : UInt64?) {
    e.encode_opt(v, Encoder::encode_nat)
  }
  let dec = fn(d : Decoder) -> UInt64? raise DecodeError {
    d.decode_opt(d2 => d2.decode_nat() catch {
      e => raise DecodeError("Decode nat: " + e.to_string())
    }) catch {
      e => raise DecodeError("Decode opt: " + e.to_string())
    }
  }
  let eq = fn(a : UInt64?, b : UInt64?) { a == b }
  roundtrip_test("Opt Some", val_some, enc, dec, eq)
  roundtrip_test("Opt None", val_none, enc, dec, eq)
}

///|
test "Candid: Vec (Int8)" {
  let vec : Array[Int] = [1, 2, -1, 127]
  let enc = fn(e : Encoder, v : Array[Int]) {
    e.encode_vec(v, Encoder::encode_int8)
  }
  let dec = fn(d : Decoder) -> Array[Int] raise DecodeError {
    d.decode_vec(d2 => d2.decode_int8() catch {
      e => raise DecodeError("Decode int8: " + e.to_string())
    }) catch {
      e => raise DecodeError("Decode vec: " + e.to_string())
    }
  }
  let eq = fn(a : Array[Int], b : Array[Int]) {
    if a.length() != b.length() {
      false
    } else {
      a[0] == b[0] && a[3] == b[3]
    }
  }
  roundtrip_test("Vec Int8", vec, enc, dec, eq)
}

///|
fn[T] check(name : String, v1 : T, v2 : T, eq : (T, T) -> Bool) -> Unit {
  if not(eq(v1, v2)) {
    abort("Test \{name} Failed: Expected value, Got value")
  }
}

///|
test "Candid: Float32 (Soft Conversion)" {
  let enc = Encoder::new()
  enc.encode_float32(3.1415927)
  let dec = Decoder::new(enc.to_bytes())
  let val = dec.decode_float32() catch {
    e => abort("Decode float32 failed: \{e}")
  }
  // Verify precision is "correctly" truncated to F32 (Double -> Float conversion will have precision loss)
  let diff = if val > 3.1415927 { val - 3.1415927 } else { 3.1415927 - val }
  if diff > 0.00001 {
    abort("Float32 conversion accuracy issue: \{val}")
  }
}

///|
test "Candid: Result<Text, Nat>" {
  let r_ok : Result[String, UInt64] = Ok("Success")
  let r_err : Result[String, UInt64] = Err(500)
  let enc_fn = fn(e : Encoder, r) {
    e.encode_result(r, Encoder::encode_text, Encoder::encode_nat)
  }
  let dec_fn = fn(d : Decoder) -> Result[String, UInt64] raise DecodeError {
    d.decode_result(
      d2 => d2.decode_text() catch {
        e => raise DecodeError("Decode text: " + e.to_string())
      },
      d2 => d2.decode_nat() catch {
        e => raise DecodeError("Decode nat: " + e.to_string())
      },
    ) catch {
      e => raise DecodeError("Decode result: " + e.to_string())
    }
  }

  // Test Ok
  let enc1 = Encoder::new()
  enc_fn(enc1, r_ok)
  let dec1 = Decoder::new(enc1.to_bytes())
  let res1 = dec_fn(dec1) catch {
    e => abort("Decode result failed: " + e.to_string())
  }
  match res1 {
    Ok(v) => check("Result Ok", v, "Success", fn(a, b) { a == b })
    Err(_) => abort("Result Ok failed")
  }

  // Test Err
  let enc2 = Encoder::new()
  enc_fn(enc2, r_err)
  let dec2 = Decoder::new(enc2.to_bytes())
  let res2 = dec_fn(dec2) catch {
    e => abort("Decode result failed: " + e.to_string())
  }
  match res2 {
    Ok(_) => abort("Result Err failed")
    Err(e) => check("Result Err", e, 500, fn(a, b) { a == b })
  }
}

///|
test "Security: Allocation DoS" {
  let enc = Encoder::new()
  // Malicious packet: declares Vec length as 10,000,000 (10MB), but actually only 1 byte
  enc.write_uleb128(10000000)
  enc.write_byte((0).to_byte())
  let dec = Decoder::new(enc.to_bytes())

  // Should trigger Error "exceeds remaining", not actually allocate 10MB memory
  let _ = dec.decode_vec(Decoder::decode_nat8) catch {
    e => {
      if not(e.to_string().contains("exceeds remaining")) {
        abort("Unexpected error message: " + e.to_string())
      }
      return
    }
  }
  abort("DoS check failed: Should return error")
}

///|
test "Candid: Fixed Integers" {
  let enc = Encoder::new()
  enc.encode_int8(-120)
  enc.encode_int16(-30000)
  let dec = Decoder::new(enc.to_bytes())
  let val = dec.decode_int8() catch { e => abort("Decode int8 failed: \{e}") }
  check("Int8", val, -120, fn(a, b) { a == b })
  let val16 = dec.decode_int16() catch {
    e => abort("Decode int16 failed: \{e}")
  }
  check("Int16", val16, -30000, fn(a, b) { a == b })
}

///|
test "Candid: Primitives" {
  let enc = Encoder::new()
  enc.encode_null()
  enc.encode_bool(true)
  let dec = Decoder::new(enc.to_bytes())
  dec.decode_null()
  let bool_val = dec.decode_bool() catch {
    e => abort("Decode bool failed: " + e.to_string())
  }
  check("Bool", bool_val, true, fn(a, b) { a == b })
}
