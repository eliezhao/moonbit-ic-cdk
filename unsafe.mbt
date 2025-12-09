// --- Unsafe Utility Module ---
// For low-level pointer operations, follows MoonBit official recommended pattern

///|
/// Use %identity to define universal type conversion
/// This is a zero-cost conversion, the compiler will directly reuse the memory representation
pub fn[Src, Dst] unsafe_cast(val : Src) -> Dst = "%identity"

///|
/// Encapsulate logic for obtaining data pointer
/// Convert FixedArray[Byte] to pointer to actual data region
/// 
/// Note: GC Header offset is currently usually 8 bytes
/// It is recommended to extract this constant for easy modification when ABI changes in the future
pub fn get_data_ptr(arr : FixedArray[Byte]) -> Int {
  // 1. Cast array reference to integer address (i.e., starting address of array object)
  let obj_addr : Int = unsafe_cast(arr)

  // 2. Add GC Header offset (currently usually 8 bytes)
  let gc_header_offset = 8
  obj_addr + gc_header_offset
}
