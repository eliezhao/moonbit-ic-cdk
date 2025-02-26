struct Reserved { }

derive(Eq, Compare, Show, Default) for Reserved

enum Empty { }

test "reserved and empty test" {
let r1 = { } // 这会调用 `Default` 派生生成的默认值
let r2 = { ..r1 } // 派生了 `Eq`，可以比较
assert_eq!(r1, r2)
}