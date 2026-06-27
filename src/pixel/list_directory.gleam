// https://sprites.dev/api/sprites/filesystem#list-directory

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/result

import pixel.{type SpriteCredentials}
import pixel/internal
import pixel/types

pub type Outcome {
  Found(path: String, count: Int, entries: List(types.FileSystemEntry))
  NotFound
}

pub type RequestBuilder {
  RequestBuilder(sprite_name: String, path: String, working_directory: String)
}

pub fn request(sprite_name: String) -> RequestBuilder {
  RequestBuilder(sprite_name:, path: "/", working_directory: "/")
}

pub fn with_path(b: RequestBuilder, path: String) -> RequestBuilder {
  RequestBuilder(..b, path:)
}

pub fn with_working_directory(
  b: RequestBuilder,
  working_directory: String,
) -> RequestBuilder {
  RequestBuilder(..b, working_directory:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  let query = [
    #("path", builder.path),
    #("workingDir", builder.working_directory),
  ]

  internal.request(
    credentials:,
    method: http.Get,
    headers: [],
    body: <<>>,
    path: "/sprites/" <> builder.sprite_name <> "/fs/list",
    query: query,
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    401 -> Error(pixel.MissingAuthenticationError)
    404 -> Ok(NotFound)
    200 -> {
      use out <- result.try(
        json.parse_bits(resp.body, decoder())
        |> result.map_error(pixel.BodyDecodeError(_, resp.body)),
      )
      Ok(out)
    }
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}

fn decoder() {
  use path <- decode.field("path", decode.string)
  use count <- decode.field("count", decode.int)
  use entries <- decode.field(
    "entries",
    decode.list(types.file_system_entry_decoder()),
  )
  decode.success(Found(path:, count:, entries:))
}
