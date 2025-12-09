// --- Internal Helper: Copy Bridge ---
// Use Unsafe module for pointer operations

///|
/// Bytes -> FixedArray[Byte]
fn bytes_to_fixed(b : Bytes) -> FixedArray[Byte] {
  let len = b.length()
  let arr = FixedArray::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 1 {
    arr[i] = b[i]
  }
  arr
}

///| FixedArray[Byte] -> Bytes

///|
/// Note: Use Buffer to construct Bytes, ensuring compatibility (Bytes are usually immutable)
fn fixed_to_bytes(arr : FixedArray[Byte]) -> Bytes {
  let len = arr.length()
  let buf = @buffer.new(size_hint=len)
  for i = 0; i < len; i = i + 1 {
    buf.write_byte(arr[i])
  }
  buf.to_bytes()
}

// --- System API Wrapper ---

///|
pub struct IC {}

///|
/// Get message caller
pub fn IC::caller() -> Principal {
  let len = msg_caller_size()
  if len == 0 {
    return Principal::anonymous()
  }
  // 1. Allocate FFI-friendly buffer (use FixedArray to create mutable buffer)
  let buf_fixed = FixedArray::make(len, (0).to_byte())
  let buf_ptr = get_data_ptr(buf_fixed)
  // 2. Call FFI to fill data
  msg_caller_copy(buf_ptr, 0, len)
  // 3. Convert to business layer Bytes
  let buf_bytes = buf_fixed.unsafe_reinterpret_as_bytes()
  Principal::from_bytes(buf_bytes)
}

///|
/// Get raw message argument (Bytes)
pub fn IC::msg_data_bytes() -> Bytes {
  let len = msg_arg_data_size()
  if len == 0 {
    return Bytes::make(0, (0).to_byte())
  }
  let buf_fixed = FixedArray::make(len, (0).to_byte())
  let buf_ptr = get_data_ptr(buf_fixed)
  msg_arg_data_copy(buf_ptr, 0, len)
  buf_fixed.unsafe_reinterpret_as_bytes()
}

///|
/// Print debug log
pub fn IC::print(msg : String) -> Unit {
  let bytes = msg.to_bytes()
  let buf_fixed = bytes.to_fixedarray()
  let buf_ptr = get_data_ptr(buf_fixed)
  debug_print(buf_ptr, bytes.length())
}

///|
/// Reply message (Raw Bytes)
pub fn IC::reply_raw(data : Bytes) -> Unit {
  let buf_fixed = data.to_fixedarray()
  let buf_ptr = get_data_ptr(buf_fixed)
  msg_reply_data_append(buf_ptr, data.length())
  msg_reply()
}

///|
/// Generic reply message
pub fn[T] IC::reply(data : T, encoder : (T) -> Bytes) -> Unit {
  let bytes = encoder(data)
  IC::reply_raw(bytes)
}

///|
/// Immediately abort and report error
pub fn IC::trap(msg : String) -> Unit {
  let bytes = msg.to_bytes()
  let buf_fixed = bytes.to_fixedarray()
  let buf_ptr = get_data_ptr(buf_fixed)
  trap(buf_ptr, bytes.length())
}

///|
/// Stable Memory: Store
pub fn IC::stable_store(offset : Int, data : Bytes) -> Unit {
  let current_pages = stable_size()
  let required_bytes = offset + data.length()
  // 1 Page = 64KB = 65536 Bytes
  let required_pages = (required_bytes + 65535) / 65536
  if required_pages > current_pages {
    let diff = required_pages - current_pages
    let res = stable_grow(diff)
    if res == -1 {
      IC::trap("Stable memory grow failed")
    }
  }
  let buf_fixed = data.to_fixedarray()
  let buf_ptr = get_data_ptr(buf_fixed)
  stable_write(offset, buf_ptr, data.length())
}

///|
/// Stable Memory: Load
pub fn IC::stable_load(offset : Int, len : Int) -> Bytes {
  let buf_fixed = FixedArray::make(len, (0).to_byte())
  let buf_ptr = get_data_ptr(buf_fixed)
  stable_read(buf_ptr, offset, len)
  buf_fixed.unsafe_reinterpret_as_bytes()
}

///|
/// Set Certified Data
pub fn IC::set_certified_data(data : Bytes) -> Unit {
  let buf_fixed = data.to_fixedarray()
  let buf_ptr = get_data_ptr(buf_fixed)
  certified_data_set(buf_ptr, data.length())
}
