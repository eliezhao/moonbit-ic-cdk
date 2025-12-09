// --- 1. Decode HttpRequest ---

///|
pub suberror DecodeError String

///|
pub fn decode_http_request(data : Bytes) -> HttpRequest raise DecodeError {
  let dec = Decoder::new(data)

  // 1. Verify DIDL header
  let magic = dec.read_bytes(4) catch {
    e => raise DecodeError("Read error: \{e}")
  }
  if magic[0] != (0x44).to_byte() ||
    magic[1] != (0x49).to_byte() ||
    magic[2] != (0x44).to_byte() ||
    magic[3] != (0x4C).to_byte() {
    raise DecodeError("Invalid Candid Header")
  }

  // 2. Skip type table (core step)
  dec.skip_type_table() catch {
    e => raise DecodeError("Skip type table error: \{e}")
  }

  // 3. Skip input argument type list (HttpRequest is the 1st argument)
  let arg_count = (dec.read_uleb128() catch {
    e => raise DecodeError("Read arg count error: \{e}")
  }).to_int()
  for i = 0; i < arg_count; i = i + 1 {
    let _ = dec.read_sleb128() catch {
      e => raise DecodeError("Read arg type error: \{e}")
    }

  }

  // 4. Read Values (strictly in Hash order)
  // url(5,843,823) < method(156,956,385) < body(1,092,319,906) < headers(1,661,489,734)

  let url = dec.decode_text() catch {
    e => raise DecodeError("Decode url error: \{e}")
  }
  let method = dec.decode_text() catch {
    e => raise DecodeError("Decode method error: \{e}")
  }
  let body = dec.decode_blob() catch {
    e => raise DecodeError("Decode body error: \{e}")
  }

  // Headers: Vec { 0: text; 1: text }
  // Tuple field names are "0" (Hash 48) and "1" (Hash 49)
  // Order: Key first, then Value
  let headers_vec = dec.decode_vec(d => {
    let k = d.decode_text() catch {
      e => raise DecodeError("Decode header key error: \{e}")
    }
    let v = d.decode_text() catch {
      e => raise DecodeError("Decode header value error: \{e}")
    }
    (k, v)
  }) catch {
    e => raise DecodeError("Decode headers error: \{e}")
  }
  { method, url, headers: headers_vec, body }
}

// --- 2. Encode HttpResponse ---

///|
pub fn encode_http_response(resp : HttpResponse) -> Bytes {
  let enc = Encoder::new()

  // 1. Write header
  enc.write_bytes(@encoding/utf8.encode("DIDL"))

  // 2. Build type table
  // Strategy: define a subtype that omits streaming_strategy
  // Receiver (IC) will treat missing opt fields as null (None)

  enc.write_uleb128(5) // Define 5 types

  // T0: HeaderField = record { 0: text; 1: text }
  // 🔴 Critical fix: Candid Tuple field indices must be integers 0 and 1
  enc.write_sleb128(TYPE_RECORD)
  enc.write_uleb128(2)
  enc.write_uleb128(0)
  enc.write_sleb128(TYPE_TEXT)
  enc.write_uleb128(1)
  enc.write_sleb128(TYPE_TEXT)

  // T1: Opt Bool (upgrade)
  enc.write_sleb128(TYPE_OPT)
  enc.write_sleb128(TYPE_BOOL)

  // T2: Vec HeaderField
  enc.write_sleb128(TYPE_VEC)
  enc.write_uleb128(0) // ref T0

  // T3: Vec Nat8 (Blob) - must be explicitly defined, cannot inline non-primitive types in Record
  enc.write_sleb128(TYPE_VEC)
  enc.write_sleb128(TYPE_NAT8)

  // T4: HttpResponse (Subtype)
  // Fields must be defined in Hash order:
  // body (1.09B) < headers (1.66B) < upgrade (1.664B) < status_code (3.47B)
  enc.write_sleb128(TYPE_RECORD)
  enc.write_uleb128(4)
  enc.write_uleb128(idl_hash("body"))
  enc.write_sleb128(3) // ref T3 (Blob)
  enc.write_uleb128(idl_hash("headers"))
  enc.write_sleb128(2) // ref T2
  enc.write_uleb128(idl_hash("upgrade"))
  enc.write_sleb128(1) // ref T1
  enc.write_uleb128(idl_hash("status_code"))
  enc.write_sleb128(TYPE_NAT16)

  // 3. Output argument type (T4)
  enc.write_uleb128(1) // 1 return value
  enc.write_sleb128(4) // Type index 4 (T4)

  // 4. Write values in T4 definition order

  // -- body --
  enc.encode_blob(resp.body)

  // -- headers --
  enc.write_uleb128(resp.headers.length().to_uint64())
  for h in resp.headers {
    enc.encode_text(h.0)
    enc.encode_text(h.1)
  }

  // -- upgrade --
  match resp.upgrade {
    None => enc.write_byte((0).to_byte())
    Some(b) => {
      enc.write_byte((1).to_byte())
      enc.encode_bool(b)
    }
  }

  // -- status_code --
  enc.encode_nat16(resp.status_code)
  enc.to_bytes()
}
