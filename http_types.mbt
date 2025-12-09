///|
pub type HeaderField = (String, String)

///|
pub(all) struct HttpRequest {
  pub method : String
  pub url : String
  pub headers : Array[HeaderField]
  pub body : Bytes
} derive(Show, Eq)

///|
pub struct StreamingCallbackToken {
  pub key : String
  pub content_encoding : String
  pub index : UInt64
} derive(Show, Eq)

///|
pub struct CallbackFunc {
  pub principal : Principal
  pub method : String
} derive(Show, Eq)

///|
pub enum StreamingStrategy {
  Callback(CallbackFunc, StreamingCallbackToken)
} derive(Show, Eq)

///|
pub(all) struct HttpResponse {
  pub status_code : UInt16
  pub headers : Array[HeaderField]
  pub body : Bytes
  pub upgrade : Bool?
  pub streaming_strategy : StreamingStrategy?
} derive(Show, Eq)
