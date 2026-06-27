import gleam/dynamic/decode
import gleam/time/timestamp

/// Decodes an RFC-3339 timestamp
pub fn timestamp_decoder() -> decode.Decoder(timestamp.Timestamp) {
  use v <- decode.then(decode.string)

  case timestamp.parse_rfc3339(v) {
    Ok(vv) -> decode.success(vv)
    Error(_) -> decode.failure(timestamp.from_unix_seconds(0), "a valid date")
  }
}
