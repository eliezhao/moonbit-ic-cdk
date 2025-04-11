fn main {}

// 获取FixedArray的头指针，前8 bytes是gc头
extern "wasm" fn getptr(x : FixedArray[Int]) -> Int =
#|(func
#|(param $arr i32)
#|(result i32)
#|(i32.add (local.get $arr) (i32.const 8)))

// input: a string
// return: "{a string}moonbit cdk"
pub fn print() -> Unit{
    // message arg size
    let msg_size : Int = @ic0.msg_arg_data_size()
    let msg_buffer = FixedArray::makei(msg_size, fn(i) { i * 0 })
    let buffer_ptr = getptr(msg_buffer)
    @ic0.msg_arg_data_copy(buffer_ptr, 0, msg_size)

    // represent: moonbitcdk
    let s : FixedArray[Int] = FixedArray::from_array([109, 111, 111, 110, 98, 105, 116, 99, 100, 107])
    let ptr = getptr(s)
    @ic0.debug_print(ptr, 40)
    @ic0.msg_reply_data_append(buffer_ptr, msg_size)
    @ic0.msg_reply_data_append(ptr, 40)
    @ic0.msg_reply()
}

// input: ()
// return: "moonbit cdk string"
pub fn api_print() -> Unit{
    // moonbit cdk
    let moonbit_str = "moonbit cdk string"
    // canister log: "moonbit cdk string"
    @ic0.debug(moonbit_str)

    // return message
    let fixed_bytes = moonbit_str.to_bytes().to_fixedarray()
    @ic0.reply(fixed_bytes)
}

// input: ()
// return: a trap message
pub fn trap_test() -> Unit{
    @ic0.trap_msg("this is a trap message")
    @ic0.msg_reply()
}

// input: ()
// return: ()
// canister log: "elapsed: ..."
pub fn instruction_counter() -> Unit{
    let start = @ic0.instruction_counter()

    let mut acc = 0
    for i = 0; i < 1000; i = i + 1 {
        acc += i
    }

    let end = @ic0.instruction_counter()
    let elapsed = end - start
    let elapsed_str = $| elapsed: \{elapsed}

    @ic0.debug(elapsed_str)
    @ic0.msg_reply()
}
