/// number.mbt
///
/// 这个模块提供了 `Int` 和 `Nat` 类型，用于任意大小的整数，
/// 支持 LEB128 编码和基本的算术运算。

/// 引入必要的模块
use @num { BigInt, BigUInt }

/// 定义 `Int` 类型，基于 `BigInt`
type Int BigInt

/// 定义 `Nat` 类型，基于 `BigUInt`
type Nat BigUInt

/// 为 `Int` 定义方法
fn Int::parse(s: String) -> Int! {
    match BigInt::from_string(s) {
        Some(i) => Int(i)
        None => fail!("Cannot parse BigInt from string")
    }
}

fn to_string(self: Int) -> String {
    self.0.to_string()
}

fn output(self: Int, logger: Logger) -> Unit {
    logger.write_string(self.to_string())
}

/// 实现 LEB128 编码和解码
fn encode(self: Int) -> Bytes {
    let value = self.0
    let mut result = Bytes::new()
    var more = true
    var val = value
    while more {
        var byte = (val & 0x7F).to_int()
        val = val >> 7
        if (val == 0 and (byte & 0x40) == 0) or (val == -1 and (byte & 0x40) != 0) {
            more = false
        } else {
            byte = byte | 0x80
        }
        result.push(byte.to_byte())
    }
    result
}

fn Int::decode(bytes: Bytes) -> Int! {
    var result = BigInt(0)
    var shift = 0
    for i = 0; i < bytes.length(); i = i + 1 {
        let byte = bytes[i].to_int()
        let low_bits = BigInt(byte & 0x7F)
        result = result | (low_bits << shift)
        shift = shift + 7
        if (byte & 0x80) == 0 {
            if (byte & 0x40) != 0 {
                result = result | (BigInt(-1) << shift)
            }
            return Int(result)
        }
    }
    fail!("LEB128 decoding failed for Int")
}

derive (Eq, Compare, Hash, Show) for Int

/// 为 `Nat` 定义方法
fn Nat::parse(s: String) -> Nat! {
    match BigUInt::from_string(s) {
        Some(n) => Nat(n)
        None => fail!("Cannot parse BigUInt from string")
    }
}

fn to_string(self: Nat) -> String {
    self.0.to_string()
}

fn output(self: Nat, logger: Logger) -> Unit {
    logger.write_string(self.to_string())
}

fn encode(self: Nat) -> Bytes {
    let mut value = self.0
    let mut result = Bytes::new()
    if value == BigUInt(0) {
        result.push(0)
        return result
    }
    while value > BigUInt(0) {
        var byte = (value & BigUInt(0x7F)).to_int()
        value = value >> 7
        if value != BigUInt(0) {
            byte = byte | 0x80
        }
        result.push(byte.to_byte())
    }
    result
}

fn Nat::decode(bytes: Bytes) -> Nat! {
    var result = BigUInt(0)
    var shift = 0
    for i = 0; i < bytes.length(); i = i + 1 {
        let byte = bytes[i].to_int()
        let low_bits = BigUInt(byte & 0x7F)
        result = result | (low_bits << shift)
        shift = shift + 7
        if (byte & 0x80) == 0 {
            return Nat(result)
        }
    }
    fail!("LEB128 decoding failed for Nat")
}

derive (Eq, Compare, Hash, Show) for Nat

/// 为 `Int` 实现算术运算符
fn op_add(self: Int, other: Int) -> Int {
    Int(self.0 + other.0)
}

fn op_sub(self: Int, other: Int) -> Int {
    Int(self.0 - other.0)
}

fn op_mul(self: Int, other: Int) -> Int {
    Int(self.0 * other.0)
}

fn op_div(self: Int, other: Int) -> Int! {
    if other.0 == BigInt(0) {
        fail!("Division by zero")
    }
    Int(self.0 / other.0)
}

fn op_mod(self: Int, other: Int) -> Int! {
    if other.0 == BigInt(0) {
        fail!("Modulo by zero")
    }
    Int(self.0 % other.0)
}

/// 为 `Nat` 实现算术运算符
fn op_add(self: Nat, other: Nat) -> Nat {
    Nat(self.0 + other.0)
}

fn op_sub(self: Nat, other: Nat) -> Nat! {
    if self.0 < other.0 {
        fail!("Result would be negative")
    }
    Nat(self.0 - other.0)
}

fn op_mul(self: Nat, other: Nat) -> Nat {
    Nat(self.0 * other.0)
}

fn op_div(self: Nat, other: Nat) -> Nat! {
    if other.0 == BigUInt(0) {
        fail!("Division by zero")
    }
    Nat(self.0 / other.0)
}

fn op_mod(self: Nat, other: Nat) -> Nat! {
    if other.0 == BigUInt(0) {
        fail!("Modulo by zero")
    }
    Nat(self.0 % other.0)
}

/// 类型转换
fn from_int(i: Int) -> Nat! {
    if i.0 < BigInt(0) {
        fail!("Cannot convert negative Int to Nat")
    }
    Nat(BigUInt(i.0))
}

fn from_nat(n: Nat) -> Int {
    Int(BigInt(n.0))
}

impl From[Int] for Nat {
    fn from(i: Int) -> Nat! {
    from_int(i)
    }
}

impl From[Nat] for Int {
    fn from(n: Nat) -> Int {
        from_nat(n)
    }
}

/// 测试用例
test "Int and Nat operations" {
    let a = Int::parse("123456789012345678901234567890")!
    let b = Int::parse("-98765432109876543210987654321")!
    let sum = a + b
    println("Sum: \{sum}") // 应该打印正确的和

    let c = Nat::parse("123456789012345678901234567890")!
    let d = Nat::parse("98765432109876543210987654321")!
    let product = c * d
    println("Product: \{product}") // 应该打印正确的乘积

    // 测试 LEB128 编码和解码
    let encoded = a.encode()
    let decoded = Int::decode(encoded)!
    assert_eq!(a, decoded)

    let encoded_nat = c.encode()
    let decoded_nat = Nat::decode(encoded_nat)!
    assert_eq!(c, decoded_nat)
}