///| wrap ic0 ffi interface=
/// 返回当前调用的用户的标识 [`Principal`](Principal)。
///
/// 等价于 Internet Computer 中 `ic_cdk::api::caller()`，返回当前调用者的 Principal ID。
pub fn caller() -> Principal {
// 获取调用者 Principal 的字节长度
let size = ic0.msg_caller_size()
// 分配字节缓冲区存储 Principal
let bytes = bytes.Bytes.init(size, fn(_i: Int) -> byte.Byte { 0.to_byte() })
// 将调用者 Principal 的字节复制到缓冲区
ic0.msg_caller_copy(bytes, 0.to_int(), size)
// 从字节创建 Principal 对象并返回
Principal.from_bytes(bytes)
}

/// 返回当前 Canister 自身的标识 [`Principal`](Principal)。
///
/// 等价于 `ic_cdk::api::id()`，获取当前 Canister 的 Principal ID。
pub fn id() -> Principal {
let size = ic0.canister_self_size()
let bytes = bytes.Bytes.init(size, fn(_i: Int) -> byte.Byte { 0.to_byte() })
ic0.canister_self_copy(bytes, 0.to_int(), size)
Principal.from_bytes(bytes)
}

/// 返回当前 Canister 的 Cycle 余额（64 位无符号）。
///
/// 对应 `ic_cdk::api::canister_balance()`。若余额超过 `UInt64` 范围，将截断高位。
pub fn canister_balance() -> UInt64 {
ic0.canister_cycle_balance()
}

/// 返回当前 Canister 的 Cycle 余额（完整 128 位）。
///
/// 对应 `ic_cdk::api::canister_balance128()`，返回完整的 Cycle 余额。
/// 使用 [`BigInt`](BigInt) 表示可能超过 64 位范围的值。
pub fn canister_balance128() -> BigInt {
// 准备16字节缓冲区用于存储结果
let buf = bytes.Bytes.init(16, fn(_i: Int) -> byte.Byte { 0.to_byte() })
// 调用系统API，将128位Cycle余额写入缓冲区（小端序）
ic0.canister_cycle_balance128(buf)
// 将小端序的16字节转换为 BigInt
// 需要将缓冲区按大端序构造以正确解析为正整数
let be_bytes = bytes.Bytes.init(16, fn(i: Int) -> byte.Byte {
buf[(15 - i).to_int()]
})
BigInt.from_octets(be_bytes)
}

/// 返回当前消息中可用的 Cycle 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_available()`，表示此次调用传入且尚未被接受的 cycles 数量，超过 `UInt64` 范围的值将被截断。
pub fn msg_cycles_available() -> UInt64 {
ic0.msg_cycles_available()
}

/// 返回当前消息中可用的 Cycle 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_available128()`，返回完整的可用 cycles 数量，使用 [`BigInt`](BigInt) 表示。
pub fn msg_cycles_available128() -> BigInt {
let buf = bytes.Bytes.init(16, fn(_i: Int) -> byte.Byte { 0.to_byte() })
ic0.msg_cycles_available128(buf)
let be_bytes = bytes.Bytes.init(16, fn(i: Int) -> byte.Byte {
buf[(15 - i).to_int()]
})
BigInt.from_octets(be_bytes)
}

/// 返回当前调用退款的 Cycle 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_refunded()`，即前一接口调用后未使用而退款的 cycles 数量，超过64位将截断。
pub fn msg_cycles_refunded() -> UInt64 {
ic0.msg_cycles_refunded()
}

/// 返回当前调用退款的 Cycle 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_refunded128()`，返回完整的退款 cycles 数量。
pub fn msg_cycles_refunded128() -> BigInt {
let buf = bytes.Bytes.init(16, fn(_i: Int) -> byte.Byte { 0.to_byte() })
ic0.msg_cycles_refunded128(buf)
let be_bytes = bytes.Bytes.init(16, fn(i: Int) -> byte.Byte {
buf[(15 - i).to_int()]
})
BigInt.from_octets(be_bytes)
}

/// 接受指定数量的循环（cycles），返回实际接受的 cycles 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_accept(max_amount: u64)`。
/// 参数为希望接受的 cycles 数量，返回实际接受的数量（可能因为可用 cycles 不足而小于请求值）。
pub fn msg_cycles_accept(max_amount: UInt64) -> UInt64 {
ic0.msg_cycles_accept(max_amount.to_int64())
}

/// 接受指定数量的循环（cycles），返回实际接受的 cycles 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_accept128(max_amount: u128)`。
/// 参数和返回值使用 [`BigInt`](BigInt) 表示，确保完整的 128 位精度。
pub fn msg_cycles_accept128(max_amount: BigInt) -> BigInt {
// 将 BigInt 拆分为高64位和低64位
// 构造 16 字节大端序表示
let input_bytes = max_amount.to_octets(16)
let high_bytes = bytes.Bytes.init(8, fn(i: Int) -> byte.Byte {
input_bytes[i]
})
let low_bytes  = bytes.Bytes.init(8, fn(i: Int) -> byte.Byte {
input_bytes[i + 8]
})
// 计算高低64位的数值
var high_val: UInt64 = 0UL
for b in high_bytes {
high_val = (high_val << 8) | b.to_int().to_uint64()
}
var low_val: UInt64 = 0UL
for b in low_bytes {
low_val = (low_val << 8) | b.to_int().to_uint64()
}
let high_i64 = high_val.to_int64()
let low_i64 = low_val.to_int64()
// 准备结果缓冲区
let result_buf = bytes.Bytes.init(16, fn(_i: Int) -> byte.Byte { 0.to_byte() })
// 调用系统API接受cycles，将实际接受量写入缓冲区（小端序）
ic0.msg_cycles_accept128(high_i64, low_i64, result_buf)
// 转换结果为 BigInt
let be_bytes = bytes.Bytes.init(16, fn(i: Int) -> byte.Byte {
result_buf[(15 - i).to_int()]
})
BigInt.from_octets(be_bytes)
}

/// 获取当前查询调用的认证数据证书。
///
/// 对应 `ic_cdk::api::data_certificate()`，仅在查询调用中有效。
/// 如果存在认证数据证书，则返回其字节内容，否则返回 `None`。
pub fn data_certificate() -> Option[bytes.Bytes] {
let size = ic0.data_certificate_size()
if size == 0 {
None
} else {
let cert = bytes.Bytes.init(size, fn(_i: Int) -> byte.Byte { 0.to_byte() })
ic0.data_certificate_copy(cert, 0.to_int(), size)
Some(cert)
}
}

/// 设置当前 Canister 的认证数据。
///
/// 对应 `ic_cdk::api::set_certified_data(data)`，将指定的数据写入认证哈希。
/// 仅允许最多32字节的数据，多余部分将被截断。
pub fn set_certified_data(data: bytes.Bytes) -> () {
let len = data.length().to_int()
// 如果数据超过32字节，只使用前32字节
let use_len = if len > 32 { 32 } else { len }
ic0.set_certified_data(data, use_len)
}

/// 返回当前系统时间（纳秒）。
///
/// 对应 `ic_cdk::api::time()`，返回 IC 运行的标准实时时间，单位为纳秒。
pub fn time() -> UInt64 {
ic0.time()
}

/// 返回性能计数器的当前值。
///
/// 对应 `ic_cdk::api::performance_counter(counter_type)`，通常用于获取指令执行量等指标。
/// `counter_type` 通常传入0表示获取已用指令数。
pub fn performance_counter(counter_type: UInt) -> UInt64 {
ic0.performance_counter(counter_type.to_int())
}

/// 打印调试消息到控制台日志。
///
/// 对应 `ic_cdk::api::print(msg)`。仅用于调试，在生产环境应避免使用。
pub fn print(msg: String) -> () {
// 将字符串转换为 UTF-8 字节序列（MoonBit 字符串内部为 UTF-16）
let utf8_bytes = msg.to_utf8()
ic0.debug_print(utf8_bytes, utf8_bytes.length().to_int())
}

/// 触发调试陷阱，终止执行并返回错误消息。
///
/// 对应 `ic_cdk::api::trap(msg)`，立即停止执行并报告错误消息。
/// 此函数不会正常返回。
pub fn trap(msg: String) -> () {
let utf8_bytes = msg.to_utf8()
ic0.trap(utf8_bytes, utf8_bytes.length().to_int())
// trap 不会返回，这里返回 Unit 仅为符合类型签名
()
}

/// 发送回复消息并结束当前调用。
///
/// 对应 `ic_cdk::api::call::reply()`，将回复数据发送给调用方。
/// 注意：调用此函数后应停止后续逻辑以避免重复回复。
pub fn reply(data: bytes.Bytes) -> () {
ic0.msg_reply_data_append(data, 0.to_int(), data.length().to_int())
ic0.msg_reply()
}

/// 拒绝当前调用并返回错误信息给调用方。
///
/// 对应 `ic_cdk::api::call::reject(msg)`，使用拒绝代码 5 表示应用自定义错误。
pub fn reject(msg: String) -> () {
let utf8_bytes = msg.to_utf8()
// 拒绝代码 5 代表 Canister 主动拒绝
ic0.msg_reject((5 : Int), utf8_bytes, utf8_bytes.length().to_int())
}

/// 返回稳定内存大小（页数，每页64KB）。
///
/// 对应 `ic_cdk::api::stable::stable_size()`。返回当前稳定内存的页数。
pub fn stable_size() -> UInt {
ic0.stable_size()
}

/// 增加稳定内存页数，返回扩展前的页数，失败则返回 `None`。
///
/// 对应 `ic_cdk::api::stable::stable_grow(pages)`。
/// 如果请求扩展成功，返回扩展前的页数；若内存不足扩展失败，返回 `None`。
pub fn stable_grow(new_pages: UInt) -> Option[UInt] {
let result = ic0.stable_grow(new_pages.to_int())
if result < 0 {
None
} else {
Some(result.to_uint())
}
}

/// 从稳定内存中读取数据。
///
/// 对应 `ic_cdk::api::stable::stable_read(offset, length)`。
/// 从稳定内存指定偏移处读取 `length` 字节并返回。
pub fn stable_read(offset: UInt, length: UInt) -> bytes.Bytes {
let buf = bytes.Bytes.init(length.to_int(), fn(_i: Int) -> byte.Byte { 0.to_byte() })
ic0.stable_read(buf, offset.to_int(), length.to_int())
buf
}

/// 向稳定内存写入数据。
///
/// 对应 `ic_cdk::api::stable::stable_write(offset, data)`。
/// 将字节序列写入稳定内存指定偏移处。
pub fn stable_write(offset: UInt, data: bytes.Bytes) -> () {
ic0.stable_write(offset.to_int(), data, 0.to_int(), data.length().to_int())
}

/// 返回稳定内存大小（页数，64位）。
///
/// 对应 `ic_cdk::api::stable::stable64_size()`，以 64 位整数返回当前稳定内存页数。
pub fn stable64_size() -> UInt64 {
ic0.stable64_size()
}

/// 增加稳定内存页数（64位），返回扩展前的页数或 `None` 表示失败。
///
/// 对应 `ic_cdk::api::stable::stable64_grow(pages)`。
/// 参数和返回值使用 64 位计数。
pub fn stable64_grow(new_pages: UInt64) -> Option[UInt64] {
let result = ic0.stable64_grow(new_pages.to_int64())
if result < 0L {
None
} else {
Some(result.to_uint64())
}
}

/// 从稳定内存（支持64位偏移）读取数据。
///
/// 对应 `ic_cdk::api::stable::stable64_read(offset, length)`。
/// 支持超过4GB偏移的读取。
pub fn stable64_read(offset: UInt64, length: UInt64) -> bytes.Bytes {
    let buf = bytes.Bytes.init(length.to_int(), fn(_i: Int) -> byte.Byte { 0.to_byte() })
    ic0.stable64_read(buf, offset.to_int64(), length.to_int64())
    buf
}

/// 向稳定内存写入数据（支持64位偏移）。
///
/// 对应 `ic_cdk::api::stable::stable64_write(offset, data)`。
/// 支持超过4GB偏移的写入。
pub fn stable64_write(offset: UInt64, data: bytes.Bytes) -> () {
    ic0.stable64_write(offset.to_int64, data, 0.to_int(), data.length().to_int())
}
