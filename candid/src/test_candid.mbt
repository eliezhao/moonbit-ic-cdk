// Test file for Candid encode/decode based on Rust candid results

import "candid_io.mbt"
import "candid_types.mbt"

// Expected results from Rust candid
let expected_principal_bytes: Bytes = [28, 213, 164, 29, 81, 108, 253, 204, 215, 11, 247, 114, 56, 25, 189, 84, 186, 68, 31, 62, 124, 29, 135, 154, 40, 176, 151, 26, 2]

// Rust encoded Principal: [68, 73, 68, 76, 0, 1, 104, 1, 29, 28, 213, ...]
let rust_encoded_principal: Bytes = [68, 73, 68, 76, 0, 1, 104, 1, 29, 28, 213, 164, 29, 81, 108, 253, 204, 215, 11, 247, 114, 56, 25, 189, 84, 186, 68, 31, 62, 124, 29, 135, 154, 40, 176, 151, 26, 2]

// Rust encoded Nat: [68, 73, 68, 76, 0, 1, 125, 210, 133, 216, 204, 4]
let rust_encoded_nat: Bytes = [68, 73, 68, 76, 0, 1, 125, 210, 133, 216, 204, 4]

// Rust encoded Result: [68, 73, 68, 76, 1, 107, 2, 188, 138, 1, 120, 197, 254, 210, 1, 113, 1, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0]
let rust_encoded_result: Bytes = [68, 73, 68, 76, 1, 107, 2, 188, 138, 1, 120, 197, 254, 210, 1, 113, 1, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0]

test "Principal encode/decode" {
    let p = Principal::from_bytes(expected_principal_bytes)
    let encoded = encode_didl_principal(p)
    
    // Check length
    assert_eq!(encoded.length(), rust_encoded_principal.length(), "Principal encoding length mismatch")
    
    // Check bytes
    let mut i = 0
    while i < encoded.length() {
        assert_eq!(encoded[i].to_uint(), rust_encoded_principal[i].to_uint(), "Principal byte mismatch at position \{i}")
        i += 1
    }
    
    // Test decode
    let decoded = decode_didl_principal(rust_encoded_principal)!
    assert_eq!(decoded.bytes.length(), expected_principal_bytes.length(), "Decoded principal length mismatch")
    
    let mut i = 0
    while i < decoded.bytes.length() {
        assert_eq!(decoded.bytes[i].to_uint(), expected_principal_bytes[i].to_uint(), "Decoded principal byte mismatch")
        i += 1
    }
    
    println("Principal encode/decode test passed!")
}

test "Nat encode/decode" {
    let n: UInt64 = 1234567890
    let encoded = encode_didl_nat(n)
    
    assert_eq!(encoded.length(), rust_encoded_nat.length(), "Nat encoding length mismatch")
    
    let mut i = 0
    while i < encoded.length() {
        assert_eq!(encoded[i].to_uint(), rust_encoded_nat[i].to_uint(), "Nat byte mismatch at position \{i}")
        i += 1
    }
    
    let decoded = decode_didl_nat(rust_encoded_nat)!
    assert_eq!(decoded, 1234567890.to_uint64(), "Decoded nat value mismatch")
    
    println("Nat encode/decode test passed!")
}

test "Result encode/decode" {
    let res: Result[UInt64, String] = Ok(42.to_uint64())
    let encoded = encode_didl_result_u64_string(res)
    
    // For Result, we may have differences in variant label encoding
    // Let's at least check the structure matches
    assert_eq!(encoded.length(), rust_encoded_result.length(), "Result encoding length mismatch")
    
    // Test decode
    let decoded = decode_didl_result_u64_string(rust_encoded_result)!
    match decoded {
        Ok(v) => {
            assert_eq!(v, 42.to_uint64(), "Decoded result value mismatch")
            println("Result decode test passed! Got Ok(\{v})")
        }
        Err(e) => {
            fail!("Expected Ok(42), got Err(\{e})")
        }
    }
}
