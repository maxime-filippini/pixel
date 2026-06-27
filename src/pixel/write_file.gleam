// https://sprites.dev/api/sprites/filesystem#write-file

import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/result
import gleam/string

import pixel.{type SpriteCredentials}
import pixel/internal
import pixel/types

pub type Outcome {
  Outcome(path: String, size: Int, mode: String)
}

pub type RequestBuilder {
  RequestBuilder(
    sprite_name: String,
    path: String,
    working_directory: String,
    mkdir: Bool,
    mode: types.FilePermission,
    content: BitArray,
  )
}

/// We set mkdir to True here, because the parameter has seemingly no influence
/// on the result, and parent directories get created no matter what.
pub fn request(
  sprite_name: String,
  path: String,
  working_directory: String,
  content: BitArray,
) -> RequestBuilder {
  RequestBuilder(
    sprite_name:,
    path:,
    working_directory:,
    mkdir: True,
    mode: types.permission_644(),
    content:,
  )
}

pub fn with_mode(builder: RequestBuilder, mode: types.FilePermission) {
  RequestBuilder(..builder, mode:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  let query = [
    #("path", builder.path),
    #("workingDir", builder.working_directory),
    #("mode", types.file_permission_to_string(builder.mode)),
    #("mkdir", bool.to_string(builder.mkdir) |> string.lowercase),
  ]

  let body = builder.content

  internal.request(
    credentials:,
    method: http.Put,
    headers: [],
    body: body,
    path: "/sprites/" <> builder.sprite_name <> "/fs/write",
    query: query,
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    200 -> {
      use out <- result.try(
        json.parse_bits(resp.body, decoder())
        |> result.map_error(pixel.BodyDecodeError(_, got: resp.body)),
      )
      Ok(out)
    }

    400 -> Error(pixel.InvalidRequestParameters(resp))
    404 -> Error(pixel.SpriteNotFound)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}

fn decoder() -> decode.Decoder(Outcome) {
  use path <- decode.field("path", decode.string)
  use size <- decode.field("size", decode.int)
  use mode <- decode.field("mode", decode.string)

  decode.success(Outcome(path:, size:, mode:))
}
