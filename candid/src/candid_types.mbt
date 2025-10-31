const TYPE_NULL      : Byte = b'\x7F'; // -1 in signed LEB128
const TYPE_BOOL      : Byte = b'\x7E'; // -2
const TYPE_NAT       : Byte = b'\x7D'; // -3
const TYPE_INT       : Byte = b'\x7C'; // -4
const TYPE_NAT8      : Byte = b'\x7B'; // -5
const TYPE_NAT16     : Byte = b'\x7A'; // -6
const TYPE_NAT32     : Byte = b'\x79'; // -7
const TYPE_NAT64     : Byte = b'\x78'; // -8
const TYPE_INT8      : Byte = b'\x77'; // -9
const TYPE_INT16     : Byte = b'\x76'; // -10
const TYPE_INT32     : Byte = b'\x75'; // -11
const TYPE_INT64     : Byte = b'\x74'; // -12
const TYPE_FLOAT32   : Byte = b'\x73'; // -13
const TYPE_FLOAT64   : Byte = b'\x72'; // -14
const TYPE_TEXT      : Byte = b'\x71'; // -15
const TYPE_RESERVED  : Byte = b'\x70'; // -16
const TYPE_EMPTY     : Byte = b'\x6F'; // -17
const TYPE_PRINCIPAL : Byte = b'\x68'; // -24  (principal special code)
const TYPE_OPTION    : Byte = b'\x6E'; // opt type constructor
const TYPE_VECTOR    : Byte = b'\x6D'; // vec type constructor
const TYPE_RECORD    : Byte = b'\x6C'; // record type constructor
const TYPE_VARIANT   : Byte = b'\x6B'; // variant type constructor

// Define MoonBit representation for Candid Principal
struct Principal {
    bytes: Bytes      // underlying byte sequence of the principal ID
}

impl Principal {
    // Construct from raw bytes
    static fn from_bytes(b: Bytes) -> Principal {
        Principal { bytes: b }
    }
    // (Optional) Construct from textual representation (e.g. "aaaaa-aa")
    static fn from_text(text: String) -> Principal! {
        fail!("Principal.from_text not implemented")
    }
    fn to_text(&self) -> String! {
        fail!("Principal.to_text not implemented")
    }
}