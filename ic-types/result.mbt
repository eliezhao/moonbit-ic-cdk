// 枚举暂时不支持小写
// /// MotokoResult 是一个泛型枚举类型，模拟 Rust 中的 MotokoResult<T,E> 实现逻辑。
// ///
// /// 它有两个分支：ok(T) 和 err(E)，分别表示成功和错误的结果。
//
// enum MotokoResult[T, E] {
//   ok(T)
//   err(E)
// }
//
// /// 将 MotokoResult 转换为标准的 Result 类型
// fn MotokoResult::into_result[T, E](self: MotokoResult[T, E]) -> Result[T, E] {
//   match self {
//     ok(v) => Ok(v)
//     err(e) => Err(e)
//   }
// }
//
// /// 为 MotokoResult 实现 From[Result[T,E]]
// /// 当给定一个标准的 Result 时，可以轻松转换为 MotokoResult
// impl From[Result[T, E]] for MotokoResult[T, E] {
//   fn from(r: Result[T, E]) -> MotokoResult[T, E] {
//     match r {
//       Ok(v) => ok(v)
//       Err(e) => err(e)
//     }
//   }
// }
//
// /// 测试用例
// test "motoko_result test" {
//   let r: Result[Int, String] = Ok(42)
//   let mr: MotokoResult[Int, String] = MotokoResult::from(r)
//   let r2 = mr.into_result()
//   assert_eq!(r2, Ok(42))
//
//   let r3: Result[Int, String] = Err("error".to_string())
//   let mr3: MotokoResult[Int, String] = MotokoResult::from(r3)
//   let r4 = mr3.into_result()
//   assert_eq!(r4, Err("error".to_string()))
// }