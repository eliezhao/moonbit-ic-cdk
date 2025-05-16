# candid-moonbit

Candid-Moonbit is a Moonbit library for parsing and serializing [Candid](https://github.com/dfinity/candid) - the interface definition language (IDL) used by the Internet Computer (IC) for describing data structures and function signatures in canisters.

## Features

* Encode Moonbit values into Candid binary format.
* Decode Candid binary data into Moonbit values.
* Support for common Candid types like `Int`, `Text`, `Principal`, `Opt`, `Vec`, `Record`, and `Variant`.
* High-performance serialization and deserialization.
* Minimal and lightweight library design.

## Installation

Add the following dependency to your project's `moon.pkg.json`:

```json
{
  "dependencies": {
    "candid-moonbit": "latest"
  }
}
```

## Usage

Here is a basic example of encoding and decoding Candid values in Moonbit:

```moonbit
import candid_moonbit;

let value = { name = "Alice", age = 30 };
let encoded = candid_moonbit.encode(value);
let decoded = candid_moonbit.decode(encoded);

debug(decoded);
```
