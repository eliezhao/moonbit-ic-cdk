// 获取FixedArray的头指针，前8 bytes是gc头
extern "wasm" fn getptr(x : FixedArray[Byte]) -> Int =
#|(func
#|(param $arr i32)
#|(result i32)
#|(i32.add (local.get $arr) (i32.const 8)))

/// 返回性能计数器的当前值。
///
/// 对应 `ic_cdk::api::performance_counter(counter_type)`，通常用于获取指令执行量等指标。
/// `counter_type` 通常传入0表示获取已用指令数。
pub fn instruction_counter() -> Int64 {
    performance_counter(0)
}

/// 打印调试消息到控制台日志。
///
/// 对应 `ic_cdk::api::print(msg)`。
pub fn debug(msg: String) -> Unit {
    // 将字符串转换为 UTF-16 字节序列
    let fixed_bytes = msg.to_bytes().to_fixedarray()
    let ptr = getptr(fixed_bytes)
    debug_print(ptr, fixed_bytes.length())
}

/// 触发调试陷阱，终止执行并返回错误消息。
///
/// 对应 `ic_cdk::api::trap(msg)`，立即停止执行并报告错误消息。
/// 此函数不会正常返回。
pub fn trap_msg(msg: String) -> Unit {
    let fixed_bytes = msg.to_bytes().to_fixedarray()
    let ptr = getptr(fixed_bytes)
    trap(ptr, fixed_bytes.length())
}

/// 发送回复消息并结束当前调用。
///
/// 对应 `ic_cdk::api::call::reply()`，将回复数据发送给调用方。
/// 注意：调用此函数后应停止后续逻辑以避免重复回复。
pub fn reply(data: FixedArray[Byte]) -> Unit {
    let ptr = getptr(data)
    msg_reply_data_append(ptr, data.length())
    msg_reply()
}

/// 拒绝当前调用并返回错误信息给调用方。
///
/// 对应 `ic_cdk::api::call::reject(msg)`，使用拒绝代码 5 表示应用自定义错误。
pub fn reject(msg: String) -> Unit {
    let fixed_bytes = msg.to_bytes().to_fixedarray()
    let ptr = getptr(fixed_bytes)
    // 拒绝代码 5 代表 Canister 主动拒绝
    msg_reject(ptr, fixed_bytes.length())
}

/// 获取当前查询调用的认证数据证书。
///
/// 对应 `ic_cdk::api::data_certificate()`，仅在查询调用中有效。
/// 如果存在认证数据证书，则返回其字节内容，否则返回 `None`。
// pub fn data_certificate() -> Option[bytes.Bytes] {
//     let size = data_certificate_size()
//     if size == 0 {
//         None
//     } else {
//         let cert = bytes.Bytes.init(size, fn(_i: Int) -> byte.Byte { 0.to_byte() })
//         data_certificate_copy(cert, 0.to_int(), size)
//         Some(cert)
//     }
// }

/// 设置当前 Canister 的认证数据。
///
/// 对应 `ic_cdk::api::set_certified_data(data)`，将指定的数据写入认证哈希。
/// 仅允许最多32字节的数据，多余部分将被截断。
// pub fn set_certified_data(data: bytes.Bytes) Unit {
//     let len = data.length().to_int()
//     // 如果数据超过32字节，只使用前32字节
//     let use_len = if len > 32 { 32 } else { len }
//     set_certified_data(data, use_len)
// }