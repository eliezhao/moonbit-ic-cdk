///|
fn main {

}

// --- 1. Replicate print (Raw Bytes) ---
// Maintain original behavior: input Bytes -> output Bytes + "moonbitcdk"

///|
pub fn print() -> Unit {
  // Get raw input (no need to calculate size/alloc/copy, library handles automatically)
  let input = @ic_cdk.IC::msg_data_bytes()

  // Concatenate suffix
  let suffix = @encoding/utf8.encode("moonbitcdk")
  let buf = @buffer.new()
  buf.write_bytes(input)
  buf.write_bytes(suffix)
  let output = buf.to_bytes()

  // Print debug log (corresponds to @ic0.debug_print)
  // Try to convert bytes to string for display, tolerate garbled text
  let debug_str = @encoding/utf8.decode_lossy(output)
  @ic_cdk.IC::print("Log: " + debug_str)

  // Reply raw data (corresponds to @ic0.msg_reply_data_append + msg_reply)
  @ic_cdk.IC::reply_raw(output)
}

// --- 2. Replicate api_print (Raw Bytes) ---
// Maintain original behavior: output raw bytes of "moonbit cdk string"

///|
pub fn api_print() -> Unit {
  let msg = "moonbit cdk string"

  // System log
  @ic_cdk.IC::print(msg)

  // Reply Raw Bytes
  @ic_cdk.IC::reply_raw(@encoding/utf8.encode(msg))
}

// --- 3. Replicate trap_test ---

///|
pub fn trap_test() -> Unit {
  @ic_cdk.IC::trap("this is a trap message")
}

// --- 4. Replicate instruction_counter ---

///|
pub fn instruction_counter() -> Unit {
  // 0 represents Instruction Counter
  let start = @ic_cdk.performance_counter(0)
  for i = 0; i < 1000; i = i + 1 {
    let _ = i

  }
  let end = @ic_cdk.performance_counter(0)
  let elapsed = end - start
  let log_msg = "elapsed: " + elapsed.to_string()
  @ic_cdk.IC::print(log_msg)
  @ic_cdk.IC::reply_raw(@encoding/utf8.encode(log_msg))
}

///|
pub fn get_caller() -> Unit {
  let caller = @ic_cdk.IC::caller()
  @ic_cdk.IC::print("Caller: " + caller.to_text())

  // Directly return Principal object
  // Use encode_one to automatically add complete Candid DIDL header
  let encoded = @ic_cdk.encode_one(
    caller,
    @ic_cdk.TYPE_PRINCIPAL,
    @ic_cdk.Encoder::encode_principal,
  )
  @ic_cdk.IC::reply_raw(encoded)
}

// --- 5. [New Feature] Get Caller and Output ---
// Use Candid encoding to return Principal text

///|
pub fn get_caller_text() -> Unit {
  // 1. Get Caller Principal object
  let caller = @ic_cdk.IC::caller()

  // 2. Convert to standard text format (automatically handles CRC32 and Base32)
  let text = caller.to_text()
  @ic_cdk.IC::print("Caller Principal: " + text)

  // 3. Use encode_one to automatically add complete Candid DIDL header
  let encoded = @ic_cdk.encode_one(
    text,
    @ic_cdk.TYPE_TEXT,
    @ic_cdk.Encoder::encode_text,
  )
  @ic_cdk.IC::reply_raw(encoded)
}

// --- 6. [New Feature] HTTP Request (Hosted Webpage) ---
// Complies with IC HTTP Gateway interface specification

///|
pub fn http_request() -> Unit {
  // 1. Try to decode request
  let input = @ic_cdk.IC::msg_data_bytes()
  let req_opt = Some(@ic_cdk.decode_http_request(input)) catch {
    @ic_cdk.DecodeError(_) => None
  }
  let req = match req_opt {
    Some(r) => r
    None => {
      // Error handling
      let empty = Bytes::make(0, (0).to_byte())
      let dummy : @ic_cdk.HttpRequest = {
        method: "",
        url: "",
        headers: [],
        body: empty,
      }
      dummy
    }
  }
  @ic_cdk.IC::print("HTTP Request URL: " + req.url)

  // 2. Construct HTML page (with CSS animation)
  let html =
    #|<!DOCTYPE html>
    #|<html lang="en">
    #|<head>
    #|    <meta charset="UTF-8">
    #|    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    #|    <title>MoonBit on ICP</title>
    #|    <style>
    #|        body {
    #|            margin: 0;
    #|            height: 100vh;
    #|            display: flex;
    #|            justify-content: center;
    #|            align-items: center;
    #|            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    #|            font-family: system-ui, -apple-system, sans-serif;
    #|            color: white;
    #|        }
    #|        .card {
    #|            background: rgba(255, 255, 255, 0.15);
    #|            backdrop-filter: blur(10px);
    #|            padding: 3rem;
    #|            border-radius: 20px;
    #|            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
    #|            border: 1px solid rgba(255, 255, 255, 0.18);
    #|            text-align: center;
    #|            max-width: 90%;
    #|            width: 400px;
    #|            animation: float 6s ease-in-out infinite;
    #|        }
    #|        @keyframes float {
    #|            0% { transform: translateY(0px); }
    #|            50% { transform: translateY(-20px); }
    #|            100% { transform: translateY(0px); }
    #|        }
    #|        h1 { margin: 0 0 10px 0; font-size: 2.5rem; letter-spacing: 1px; }
    #|        p { font-size: 1.1rem; opacity: 0.9; line-height: 1.5; }
    #|        code { background: rgba(0,0,0,0.2); padding: 2px 6px; border-radius: 4px; }
    #|        .tag {
    #|            display: inline-block; margin-top: 20px;
    #|            padding: 8px 16px; background: #ff0055;
    #|            border-radius: 50px; font-weight: bold; font-size: 0.9rem;
    #|        }
    #|    </style>
    #|</head>
    #|<body>
    #|    <div class="card">
    #|        <h1>🚀 MoonBit</h1>
    #|        <p>High Performance WebAssembly<br>on Internet Computer</p>
    #|        <div style="margin: 20px 0; height: 1px; background: rgba(255,255,255,0.3);"></div>
    #|        <p style="font-size: 0.9rem">Request Path:<br><code>\{req.url}</code></p>
    #|        <div class="tag">Powered by MoonBit</div>
    #|    </div>
    #|</body>
    #|</html>
  let body_bytes = @encoding/utf8.encode(html)

  // 3. Construct HttpResponse
  let resp : @ic_cdk.HttpResponse = {
    status_code: 200,
    headers: [
      ("Content-Type", "text/html; charset=utf-8"),
      ("Content-Length", body_bytes.length().to_string()),
      ("X-Powered-By", "MoonBit CDK"),
    ],
    body: body_bytes,
    upgrade: None,
    streaming_strategy: None,
  }

  // 4. Reply
  @ic_cdk.IC::reply(resp, @ic_cdk.encode_http_response)
}
