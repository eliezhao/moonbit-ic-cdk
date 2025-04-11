///! moonbit IC0 FFI

///|
pub fn msg_arg_data_size() -> Int = "ic0" "msg_arg_data_size";

///|
pub fn msg_arg_data_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_arg_data_copy";

///|
pub fn msg_caller_size() -> Int = "ic0" "msg_caller_size";

///|
pub fn msg_caller_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_caller_copy";

///|
pub fn msg_reject_code() -> Int = "ic0" "msg_reject_code";

///|
pub fn msg_reject_msg_size() -> Int = "ic0" "msg_reject_msg_size";

///|
pub fn msg_reject_msg_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_reject_msg_copy";

///|
pub fn msg_reply_data_append(src: Int, size: Int) = "ic0" "msg_reply_data_append";

///|
pub fn msg_reply() = "ic0" "msg_reply";

///|
pub fn msg_reject(src: Int, size: Int) = "ic0" "msg_reject";

///|
pub fn msg_cycles_available() -> Int64 = "ic0" "msg_cycles_available";

///|
pub fn msg_cycles_available128(dst: Int) = "ic0" "msg_cycles_available128";

///|
pub fn msg_cycles_refunded() -> Int64 = "ic0" "msg_cycles_refunded";

///|
pub fn msg_cycles_refunded128(dst: Int) = "ic0" "msg_cycles_refunded128";

///|
pub fn msg_cycles_accept(max_amount: Int64) -> Int64 = "ic0" "msg_cycles_accept";

///|
pub fn msg_cycles_accept128(max_amount_high: Int64, max_amount_low: Int64, dst: Int) = "ic0" "msg_cycles_accept128";

///|
pub fn cycles_burn128(amount_high: Int64, amount_low: Int64, dst: Int) = "ic0" "cycles_burn128";

///|
pub fn canister_self_size() -> Int = "ic0" "canister_self_size";

///|
pub fn canister_self_copy(dst: Int, offset: Int, size: Int) = "ic0" "canister_self_copy";

///|
pub fn canister_cycle_balance() -> Int64 = "ic0" "canister_cycle_balance";

///|
pub fn canister_cycle_balance128(dst: Int) = "ic0" "canister_cycle_balance128";

///|
pub fn canister_status() -> Int = "ic0" "canister_status";

///|
pub fn canister_version() -> Int64 = "ic0" "canister_version";

///|
pub fn msg_method_name_size() -> Int = "ic0" "msg_method_name_size";

///|
pub fn msg_method_name_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_method_name_copy";

///|
pub fn accept_message() = "ic0" "accept_message";

///|
pub fn call_new(
callee_src: Int,
callee_size: Int,
name_src: Int,
name_size: Int,
reply_fun: Int,
reply_env: Int,
reject_fun: Int,
reject_env: Int
) = "ic0" "call_new";

///|
pub fn call_on_cleanup(fun: Int, env: Int) = "ic0" "call_on_cleanup";

///|
pub fn call_data_append(src: Int, size: Int) = "ic0" "call_data_append";

///|
pub fn call_cycles_add(amount: Int64) = "ic0" "call_cycles_add";

///|
pub fn call_cycles_add128(amount_high: Int64, amount_low: Int64) = "ic0" "call_cycles_add128";

///|
pub fn call_perform() -> Int = "ic0" "call_perform";

///|
pub fn stable_size() -> Int = "ic0" "stable_size";

///|
pub fn stable_grow(new_pages: Int) -> Int = "ic0" "stable_grow";

///|
pub fn stable_write(offset: Int, src: Int, size: Int) = "ic0" "stable_write";

///|
pub fn stable_read(dst: Int, offset: Int, size: Int) = "ic0" "stable_read";

///|
pub fn stable64_size() -> Int64 = "ic0" "stable64_size";

///|
pub fn stable64_grow(new_pages: Int64) -> Int64 = "ic0" "stable64_grow";

///|
pub fn stable64_write(offset: Int64, src: Int64, size: Int64) = "ic0" "stable64_write";

///|
pub fn stable64_read(dst: Int64, offset: Int64, size: Int64) = "ic0" "stable64_read";

///|
pub fn certified_data_set(src: Int, size: Int) = "ic0" "certified_data_set";

///|
pub fn data_certificate_present() -> Int = "ic0" "data_certificate_present";

///|
pub fn data_certificate_size() -> Int = "ic0" "data_certificate_size";

///|
pub fn data_certificate_copy(dst: Int, offset: Int, size: Int) = "ic0" "data_certificate_copy";

///|
pub fn time() -> Int64 = "ic0" "time";

///|
pub fn global_timer_set(timestamp: Int64) -> Int64 = "ic0" "global_timer_set";

///|
pub fn performance_counter(counter_type: Int) -> Int64 = "ic0" "performance_counter";

///|
pub fn is_controller(src: Int, size: Int) -> Int = "ic0" "is_controller";

///|
pub fn in_replicated_execution() -> Int = "ic0" "in_replicated_execution";

///|
pub fn debug_print(src: Int, size: Int) = "ic0" "debug_print";

///|
pub fn trap(src: Int, size: Int) = "ic0" "trap";