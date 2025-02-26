///! moonbit IC0 FFI

///|
fn msg_arg_data_size() -> Int = "ic0" "msg_arg_data_size";

///|
fn msg_arg_data_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_arg_data_copy";

///|
fn msg_caller_size() -> Int = "ic0" "msg_caller_size";

///|
fn msg_caller_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_caller_copy";

///|
fn msg_reject_code() -> Int = "ic0" "msg_reject_code";

///|
fn msg_reject_msg_size() -> Int = "ic0" "msg_reject_msg_size";

///|
fn msg_reject_msg_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_reject_msg_copy";

///|
fn msg_reply_data_append(src: Int, size: Int) = "ic0" "msg_reply_data_append";

///|
pub fn msg_reply() = "ic0" "msg_reply";

///|
fn msg_reject(src: Int, size: Int) = "ic0" "msg_reject";

///|
fn msg_cycles_available() -> Int64 = "ic0" "msg_cycles_available";

///|
fn msg_cycles_available128(dst: Int) = "ic0" "msg_cycles_available128";

///|
fn msg_cycles_refunded() -> Int64 = "ic0" "msg_cycles_refunded";

///|
fn msg_cycles_refunded128(dst: Int) = "ic0" "msg_cycles_refunded128";

///|
fn msg_cycles_accept(max_amount: Int64) -> Int64 = "ic0" "msg_cycles_accept";

///|
fn msg_cycles_accept128(max_amount_high: Int64, max_amount_low: Int64, dst: Int) = "ic0" "msg_cycles_accept128";

///|
fn cycles_burn128(amount_high: Int64, amount_low: Int64, dst: Int) = "ic0" "cycles_burn128";

///|
fn canister_self_size() -> Int = "ic0" "canister_self_size";

///|
fn canister_self_copy(dst: Int, offset: Int, size: Int) = "ic0" "canister_self_copy";

///|
fn canister_cycle_balance() -> Int64 = "ic0" "canister_cycle_balance";

///|
fn canister_cycle_balance128(dst: Int) = "ic0" "canister_cycle_balance128";

///|
fn canister_status() -> Int = "ic0" "canister_status";

///|
fn canister_version() -> Int64 = "ic0" "canister_version";

///|
fn msg_method_name_size() -> Int = "ic0" "msg_method_name_size";

///|
fn msg_method_name_copy(dst: Int, offset: Int, size: Int) = "ic0" "msg_method_name_copy";

///|
fn accept_message() = "ic0" "accept_message";

///|
fn call_new(
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
fn call_on_cleanup(fun: Int, env: Int) = "ic0" "call_on_cleanup";

///|
fn call_data_append(src: Int, size: Int) = "ic0" "call_data_append";

///|
fn call_cycles_add(amount: Int64) = "ic0" "call_cycles_add";

///|
fn call_cycles_add128(amount_high: Int64, amount_low: Int64) = "ic0" "call_cycles_add128";

///|
fn call_perform() -> Int = "ic0" "call_perform";

///|
fn stable_size() -> Int = "ic0" "stable_size";

///|
fn stable_grow(new_pages: Int) -> Int = "ic0" "stable_grow";

///|
fn stable_write(offset: Int, src: Int, size: Int) = "ic0" "stable_write";

///|
fn stable_read(dst: Int, offset: Int, size: Int) = "ic0" "stable_read";

///|
fn stable64_size() -> Int64 = "ic0" "stable64_size";

///|
fn stable64_grow(new_pages: Int64) -> Int64 = "ic0" "stable64_grow";

///|
fn stable64_write(offset: Int64, src: Int64, size: Int64) = "ic0" "stable64_write";

///|
fn stable64_read(dst: Int64, offset: Int64, size: Int64) = "ic0" "stable64_read";

///|
fn certified_data_set(src: Int, size: Int) = "ic0" "certified_data_set";

///|
fn data_certificate_present() -> Int = "ic0" "data_certificate_present";

///|
fn data_certificate_size() -> Int = "ic0" "data_certificate_size";

///|
fn data_certificate_copy(dst: Int, offset: Int, size: Int) = "ic0" "data_certificate_copy";

///|
fn time() -> Int64 = "ic0" "time";

///|
fn global_timer_set(timestamp: Int64) -> Int64 = "ic0" "global_timer_set";

///|
fn performance_counter(counter_type: Int) -> Int64 = "ic0" "performance_counter";

///|
fn is_controller(src: Int, size: Int) -> Int = "ic0" "is_controller";

///|
fn in_replicated_execution() -> Int = "ic0" "in_replicated_execution";

///|
pub fn debug_print(src: Int, size: Int) = "ic0" "debug_print";

///|
fn trap(src: Int, size: Int) = "ic0" "trap";