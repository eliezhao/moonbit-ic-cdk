////////////////////////////////////////////////////////////////////////////////
// principal.mbt
////////////////////////////////////////////////////////////////////////////////

// todo: crc32: https://github.com/gmlewis/moonbit-crc32

////////////////////////////////////////////////////////////////////////////////
// 1. 错误类型
////////////////////////////////////////////////////////////////////////////////

type! PrincipalError {
    BytesTooLong
    InvalidBase32
    TextTooShort
    TextTooLong
    CheckSequenceNotMatch
    AbnormalGrouped(p~ : Principal)
}

////////////////////////////////////////////////////////////////////////////////
// 2. 工具函数：字符串操作
////////////////////////////////////////////////////////////////////////////////

fn char_at(s: String, i: Int) -> Char {
    if i < 0 || i >= s.length() {
        let t : Char = '0'
        t
    } else {
        s[i]
    }
}

fn to_upper(s: String) -> String {
s.to_upper()
// let mut r = ""
// let mut i = 0
// while i < s.length() {
//     let c = char_at(s, i)
//     let code = c.to_int()
//     // 'a'..'z' => 97..122
//     if code >= 97 && code <= 122 {
//         let upper_code = code - 32
//         r = r + upper_code.to_string()
//     } else {
//         r = r + c.to_string()
//     }
//     i = i + 1
// }
// r
}

fn to_lower(s: String) -> String {
s.to_lower()
// let mut r = ""
// let mut i = 0
// while i < s.length() {
//     let c = char_at(s, i)
//     let code = c.to_char().to_int()
//     // 'A'..'Z' => 65..90
//     if code >= 65 && code <= 90 {
//     let lower_code = code + 32
//     r = r + Char(lower_code).to_string()
// } else {
//     r = r + c
// }
//     i = i + 1
// }
// r
}

fn remove_char(s: String, ch: Char) -> String {
    let mut r = ""
    let mut i = 0
    while i < s.length() {
        let c = char_at(s, i)
        if c != ch {
            r = r + c.to_string()
        }
        i = i + 1
    }
    r
}

fn string_slice(s: String, start: Int, length: Int) -> String {
    if start < 0 || length < 0 || start + length > s.length() {
        ""
    } else {
        s[start:start+length].to_string()
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3. Base32 编解码
////////////////////////////////////////////////////////////////////////////////

/// 简易 Base32 编码
fn base32_encode(data: Bytes) -> String {
    // 定义 Base32 字母表
    let base32_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    let mut bits = 0
    let mut bits_len = 0
    let mut output = ""
    let mut i = 0

    while i < data.length() {
        let val = data[i].to_int() & 0xFF
        bits = (bits << 8) | val
        bits_len = bits_len + 8

        while bits_len >= 5 {
            bits_len = bits_len - 5
            let index = (bits >> bits_len) & 0x1F
            let ch = string_slice(base32_alphabet, index, 1)
            output = output + ch
        }
        i = i + 1
    }

    // 处理剩余不足 5 位的部分
    if bits_len > 0 {
        let index = (bits << (5 - bits_len)) & 0x1F
        let ch = string_slice(base32_alphabet, index, 1)
        output = output + ch
    }

    // 根据 RFC 4648，要使输出长度为 8 的倍数，所以补充 '=' 字符
    let mod = output.length() % 8
    if mod != 0 {
        let pad_count = 8 - mod
        let mut j = 0
        while j < pad_count {
            output = output + "="
            j = j + 1
        }
    }

    output
}

/// 简易 Base32 解码
fn base32_decode(s: String) -> Bytes!PrincipalError {
    // 函数体内声明 base32_alphabet
    let base32_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    let up = to_upper(s)
    let s2 = remove_char(up, '-')

    let mut bits = 0
    let mut bits_len = 0
    let buf : @buffer.T = @buffer.new()

    let mut i = 0
    while i < s2.length() {
        let c = char_at(s2, i)
        let idx = base32_find_index(c.to_string(), base32_alphabet)
        if idx < 0 {
            raise InvalidBase32
        }
        bits = (bits << 5) | idx
        bits_len = bits_len + 5
        if bits_len >= 8 {
            bits_len = bits_len - 8
            let byte = (bits >> bits_len) & 0xFF
            buf.write_byte(byte.to_byte())
        }
        i = i + 1
    }
    buf.to_bytes()
}

/// 在 base32_alphabet 中查找字符下标
fn base32_find_index(ch: String, base32_alphabet: String) -> Int {
    let mut i = 0
    while i < base32_alphabet.length() {
        let c0 = char_at(base32_alphabet, i)
        if c0.to_string() == ch {
            return i
        }
        i = i + 1
    }
    -1
}

////////////////////////////////////////////////////////////////////////////////
// 4. Principal 结构
////////////////////////////////////////////////////////////////////////////////

const MAX_LENGTH_IN_BYTES: Int = 29;
const ANONYMOUS_TAG: UInt = 4;

struct Principal {
    len: UInt
    bytes : Bytes
} derive(Eq)

/// 构造 management_canister
fn Principal::management_canister() -> Principal {
    let fixed_array = FixedArray::make(MAX_LENGTH_IN_BYTES, b'0')
    Principal::{
        len: 0,
        bytes: Bytes::from_fixedarray(fixed_array)
    }
}

/// 构造匿名 principal
fn Principal::anonymous() -> Principal {
    let arr: FixedArray[Byte] = FixedArray::make(MAX_LENGTH_IN_BYTES, b'0')
    arr[0] = b'4'
    Principal::{
        len: 1,
        bytes: Bytes::from_fixedarray(arr)
    }
}

/// 私有构造：若 > 29 则 fail
fn Principal::from_slice(slice: Bytes) -> Principal!PrincipalError {
    if slice.length() > MAX_LENGTH_IN_BYTES {
        raise PrincipalError::BytesTooLong
    }
    let arr: FixedArray[Byte] = FixedArray::make(MAX_LENGTH_IN_BYTES, b'0')
    let len = slice.length()
    let mut i = 0
    while i < len {
        arr[i] = slice[i]
        i = i + 1
    }
    Principal::{
        len: len.reinterpret_as_uint(),
        bytes: Bytes::from_fixedarray(arr)
    }
}

/// from_text：只做 base32 解码 => 长度检查 => roundtrip
fn Principal::from_text(text: String) -> Principal!PrincipalError {
    let max_len = 29
    let decoded = base32_decode!(text)
    if decoded.length() > max_len {
        raise TextTooLong
    }
    let p = Principal::from_slice!(decoded)
    p
}

/// 返回 Principal 实际存储字节的切片（范围 0 .. len）。
fn Principal::as_slice(self: Principal) -> Bytes {
    self.bytes
}

// todo: 要进一步完善base32 encode
/// to_text：base32 编码 + 每5字符插入 '-' + 转小写
fn to_text(self: Principal) -> String {
    let base32_str = base32_encode(self.bytes)
    let mut s = base32_str
    let mut result = ""

    while s.length() > 5 {
        let head = string_slice(s, 0, 5)
        result = result + head + "-"
        s = string_slice(s, 5, s.length() - 5)
    }
    result = result + s
    to_lower(result)
}

////////////////////////////////////////////////////////////////////////////////
// 5. 测试
////////////////////////////////////////////////////////////////////////////////

test "principal test" {

    let test_principal_text = "ytoqu-ey42w-sb2ul-m7xgn-oc7xo-i4btp-kuxjc-b6pt4-dwdzu-kfqs4-nae"
    let test_principal_slice: Bytes = [28, 213, 164, 29, 81, 108, 253, 204, 215, 11, 247, 114, 56, 25, 189, 84, 186, 68, 31, 62, 124, 29, 135, 154, 40, 176, 151, 26, 2]

    // let p = Principal::management_canister()
    // assert_eq!(p.len, 0)

    // let txt = p.to_text()
    let re_principal = try {
        Principal::from_slice!(test_principal_slice)
    } catch {
        e => fail!("principal from slice failed")
    } else {
        v => v
    }
    println(re_principal.to_text())

    assert_eq!(test_principal_slice, re_principal.as_slice())
    // assert_eq!(test_principal_text, re_principal.to_text())
}