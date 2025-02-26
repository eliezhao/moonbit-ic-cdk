/// 定义常量，与Rust代码中一致
let CONTINUATION_BIT : Int = 1 << 7
let SIGN_BIT : Int = 1 << 6

/// 对于错误处理，这里简单使用 fail! 抛出错误，当出现无效数据或溢出时。
/// 如果需要可以定义专门的错误类型并返回 Result[T]!Error。

/// encode_nat：将非负整数nat以LEB128格式编码到Bytes中
fn encode_nat(val : Int) -> Bytes! {
  if val < 0 {
    fail!("encode_nat: val must be non-negative")
  }
  let mut result = Bytes::new()
  var current = val
  loop {
    var byte = (current & 0x7f).to_int() // 取低7位
    current = current >> 7
    if current != 0 {
      // 还有更多数据
      byte = byte | CONTINUATION_BIT
    }
    result.push(byte.to_byte())
    if current == 0 {
      return result
    }
  }
}

/// decode_nat：从LEB128格式的Bytes解码出非负整数
fn decode_nat(data : Bytes) -> Int! {
  var result = 0
  var shift = 0
  var i = 0
  while i < data.length() {
    let byte = data[i].to_int()
    i = i + 1
    // 检查溢出条件
    if shift == 127 && byte != 0x00 && byte != 0x01 {
      // consume remainder
      while (byte & CONTINUATION_BIT) != 0 && i < data.length() {
        i = i + 1
      }
      fail!("nat overflow")
    }
    let low_bits = byte & 0x7f
    result = result | (low_bits << shift)
    if (byte & CONTINUATION_BIT) == 0 {
      return result
    }
    shift = shift + 7
  }
  fail!("decode_nat: unexpected end of data")
}

/// encode_int：将有符号整数val以LEB128格式编码到Bytes中
fn encode_int(val : Int) -> Bytes! {
  let mut result = Bytes::new()
  var current = val
  loop {
    var byte = (current & 0xff).to_int()
    current = current >> 6
    let done = (current == 0 || current == -1)
    if done {
      byte = byte & (0xff - CONTINUATION_BIT).to_int() // 清掉 continuation bit
    } else {
      current = current >> 1
      byte = byte | CONTINUATION_BIT
    }
    result.push(byte.to_byte())
    if done {
      return result
    }
  }
}

/// decode_int：从LEB128格式的Bytes解码出有符号整数
fn decode_int(data : Bytes) -> Int! {
  var result = 0
  var shift = 0
  let size = 128
  var i = 0
  var byte = 0
  while i < data.length() {
    let b = data[i].to_int()
    i = i + 1
    byte = b
    // 检查溢出条件
    if shift == 127 && byte != 0x00 && byte != 0x7f {
      // consume remainder
      while (byte & CONTINUATION_BIT) != 0 && i < data.length() {
        let nb = data[i].to_int()
        i = i + 1
        byte = nb
      }
      fail!("int overflow")
    }
    let low_bits = (byte & 0x7f)
    result = result | (low_bits << shift)
    shift = shift + 7
    if (byte & CONTINUATION_BIT) == 0 {
      break
    }
  }
  if shift < size && (byte & SIGN_BIT) == SIGN_BIT {
    result = result | (~0 << shift)
  }
  return result
}

/// 测试用例
test "leb128 test" {
  let x = 624485 // 0xED 0xC7 0x01 in LEB128 for unsigned
  let encoded = encode_nat(x)!
  assert_eq!(encoded, [0xED, 0xC7, 0x01].map(fn(i) { i.to_byte() }))
  let decoded = decode_nat(encoded)!
  assert_eq!(decoded, x)

  // 测试负数
  let y = -123456
  let enc_i = encode_int(y)!
  let dec_i = decode_int(enc_i)!
  assert_eq!(dec_i, y)
}