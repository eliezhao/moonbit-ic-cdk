extern "wasm" fn getptr(x : FixedArray[Int]) -> Int =
#|(func
#|(param $arr i32)
#|(result i32)
#|(i32.add (local.get $arr) (i32.const 8)))