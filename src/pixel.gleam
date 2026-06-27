/// A client for the fly.io Sprites API.
/// 
/// Currently a work in progress.
/// 
/// Reference docs: https://sprites.dev/api/sprites 
/// 
import gleam/http/response
import gleam/json

pub const root_url: String = "https://api.sprites.dev/v1"

pub type SpriteCredentials {
  SpriteCredentials(org: String, token: String)
}

/// The base credential constructor
pub fn credentials(org org: String, token token: String) {
  SpriteCredentials(org:, token:)
}

pub type Error {
  UnexpectedResponseError(response.Response(BitArray))
  BodyDecodeError(error: json.DecodeError, got: BitArray)
  MissingAuthenticationError
  InvalidRequestParameters(response.Response(BitArray))
  ResourceNotFound
  SpriteNotFound
  SpriteAlreadyExists
  ResponseEncodingError(BitArray)
}
