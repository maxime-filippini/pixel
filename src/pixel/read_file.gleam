import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import pixel.{type SpriteCredentials}
import pixel/internal

pub type Outcome {
  Found(contents: BitArray)
  NotFound
}

pub type RequestBuilder {
  RequestBuilder(sprite_name: String, path: String, working_directory: String)
}

pub fn request(
  sprite_name sprite_name: String,
  path path: String,
  working_directory working_directory: String,
) -> RequestBuilder {
  RequestBuilder(sprite_name:, path:, working_directory:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  let query = [
    #("path", builder.path),
    #("workingDir", builder.path),
  ]
  internal.request(
    credentials:,
    method: http.Get,
    headers: [],
    body: <<>>,
    path: "ur/sprites/" <> builder.sprite_name <> "/fs/read",
    query: query,
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    401 -> Error(pixel.MissingAuthenticationError)
    200 -> {
      Ok(Found(resp.body))
    }
    404 -> {
      // If a field called `path` exists on the error response, then it's because
      // the file was missing. Otherwise, it's because the sprite is not found.
      let path_decoder = {
        use path <- decode.field("path", decode.string)
        use error <- decode.field("error", decode.string)
        decode.success(#(path, error))
      }

      case json.parse_bits(resp.body, path_decoder) {
        Ok(_) -> Ok(NotFound)
        Error(_) -> Error(pixel.SpriteNotFound)
      }
    }
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
