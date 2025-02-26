/// candid.mbt

////////////////////////////////////////////////////////////////////////////////
// 占位：基础类型定义
////////////////////////////////////////////////////////////////////////////////

type SerializeError = String

// 在MoonBit中可以使用 `Ok(T)` 或 `Err(E)`，这里示例保持与Rust类似的 Result 表达。
// 也可使用 `Result[T, E]` 类型别名，或者直接使用 (T)!E 形式。
type Result[T, E] = (Ok(T) | Err(E))

////////////////////////////////////////////////////////////////////////////////
// 占位：Candid 类型系统（Type, TypeInner）
////////////////////////////////////////////////////////////////////////////////

enum Type {
inner : TypeInner
}

enum TypeInner {
Unknown
Knot(String)
Bool
Int
Nat
Text
// ... 这里可以按需求扩充
}

// 模拟 find_type, env_add, env_id
// 原 Rust 代码中提到 self::internal::find_type(&id), env_add, env_id
// 在MoonBit里可以自定义这些函数为占位或做简单缓存。
fn find_type(_id : String) -> Option[Type] {
None
}
fn env_add(_id : String, _ty : Type) -> Unit {
// no-op
}
fn env_id(_id : String, _ty : Type) -> Unit {
// no-op
}

////////////////////////////////////////////////////////////////////////////////
// Trait: CandidType
////////////////////////////////////////////////////////////////////////////////

trait CandidType {
// 模拟 Rust 中的 id() -> TypeId
// 由于 MoonBit 没有完全等价的 TypeId::of::<Self>()，我们用字符串占位。
fn id() -> String {
// 占位：可以用 "TypeName" 或 Hash
"anonymous_type_id"
}

// 模拟 "ty()" 方法，带缓存
fn ty() -> Type {
let id = Self::id()
match find_type(id) {
Some(t0) => match t0.inner {
Unknown => { inner: Knot(id) }
_ => t0
}
None => {
env_add(id, { inner: Unknown })
let t1 = Self::_ty()
env_add(id, t1)
env_id(id, t1)
t1
}
}
}

// 由用户自行实现，返回实际的Type
fn _ty() -> Type

// 序列化自身到 Serializer 中
fn idl_serialize[S: Serializer](self, serializer: S) -> Result[Unit, S::Error]
}

////////////////////////////////////////////////////////////////////////////////
// Trait: Serializer
////////////////////////////////////////////////////////////////////////////////

trait Serializer {
// 与 Rust 中相同：Error类型
type Error
// 复合类型的序列化器
type Compound : Compound<Error = Self::Error>

fn serialize_bool(self, v: Bool) -> Result[Unit, Self::Error]

// 如果有bignum功能，可以定义 serialize_int(self, v: Int) ...
// 这里示例和原代码一致
fn serialize_int(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_i128(self, v: Int) -> Result[Unit, Self::Error]

fn serialize_nat(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_u128(self, v: Int) -> Result[Unit, Self::Error]

fn serialize_nat8(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_nat16(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_nat32(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_nat64(self, v: Int) -> Result[Unit, Self::Error]

fn serialize_int8(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_int16(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_int32(self, v: Int) -> Result[Unit, Self::Error]
fn serialize_int64(self, v: Int) -> Result[Unit, Self::Error]

fn serialize_float32(self, v: Float) -> Result[Unit, Self::Error]
fn serialize_float64(self, v: Double) -> Result[Unit, Self::Error]

fn serialize_text(self, v: String) -> Result[Unit, Self::Error]
fn serialize_null(self, v: Unit) -> Result[Unit, Self::Error]
fn serialize_empty(self) -> Result[Unit, Self::Error]

fn serialize_option[T: CandidType + ?Sized](self, v: Option[T]) -> Result[Unit, Self::Error]

fn serialize_struct(self) -> Result[Self::Compound, Self::Error]
fn serialize_vec(self, len: Int) -> Result[Self::Compound, Self::Error]
fn serialize_blob(self, v: Bytes) -> Result[Unit, Self::Error]

fn serialize_variant(self, index: Int) -> Result[Self::Compound, Self::Error]

fn serialize_principal(self, v: Bytes) -> Result[Unit, Self::Error]
fn serialize_function(self, v: Bytes, meth: String) -> Result[Unit, Self::Error]
}

////////////////////////////////////////////////////////////////////////////////
// Trait: Compound
////////////////////////////////////////////////////////////////////////////////

trait Compound {
type Error

fn serialize_element[T: CandidType + ?Sized](self: Compound, v: T)
-> Result[Unit, Self::Error]

fn serialize_blob(self: Compound, blob: Bytes) -> Result[Unit, Self::Error]
}