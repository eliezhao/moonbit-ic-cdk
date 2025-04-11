// /// 返回稳定内存大小（页数，每页64KB）。
// ///
// /// 对应 `ic_cdk::api::stable::stable_size()`。返回当前稳定内存的页数。
// pub func stable_size() -> Int {
//     stable_size()
// }
//
// /// 增加稳定内存页数，返回扩展前的页数，失败则返回 `None`。
// ///
// /// 对应 `ic_cdk::api::stable::stable_grow(pages)`。
// /// 如果请求扩展成功，返回扩展前的页数；若内存不足扩展失败，返回 `None`。
// pub func stable_grow(new_pages: UInt) -> Option[UInt] {
//     let result = stable_grow(new_pages.to_int())
//     if result < 0 {
//         None
//     } else {
//         Some(result.to_uint())
//     }
// }
//
// /// 从稳定内存中读取数据。
// ///
// /// 对应 `ic_cdk::api::stable::stable_read(offset, length)`。
// /// 从稳定内存指定偏移处读取 `length` 字节并返回。
// pub func stable_read(offset: UInt, length: UInt) -> bytes.Bytes {
//     let buf = bytes.Bytes.init(length.to_int(), func(_i: Int) -> byte.Byte { 0.to_byte() })
//     stable_read(buf, offset.to_int(), length.to_int())
//     buf
// }
//
// /// 向稳定内存写入数据。
// ///
// /// 对应 `ic_cdk::api::stable::stable_write(offset, data)`。
// /// 将字节序列写入稳定内存指定偏移处。
// pub func stable_write(offset: Int, data: bytes.Bytes) -> () {
//     stable_write(offset.to_int(), data, 0.to_int(), data.length().to_int())
// }
