// https://sprites.dev/api/sprites/checkpoints#create-checkpoint

// https://sprites.dev/api/sprites#get

import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/result
import pixel.{type SpriteCredentials}
import pixel/internal
import pixel/types

pub type RequestBuilder {
  RequestBuilder(name: String, comment: String)
}

pub fn request(name name: String, comment comment: String) -> RequestBuilder {
  RequestBuilder(name:, comment:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  internal.request(
    credentials:,
    method: http.Post,
    headers: [#("content-type", "application/json")],
    body: json.object([#("comment", json.string(builder.comment))])
      |> json.to_string
      |> bit_array.from_string,
    path: "/sprites/" <> builder.name <> "/checkpoint",
    query: [],
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(types.SpriteCheckpoint, pixel.Error) {
  case resp.status {
    200 -> {
      use checkpoint <- result.try(
        json.parse_bits(resp.body, types.checkpoint_decoder())
        |> result.map_error(pixel.BodyDecodeError(_, got: resp.body)),
      )
      Ok(checkpoint)
    }
    401 -> Error(pixel.MissingAuthenticationError)
    404 -> Error(pixel.SpriteNotFound)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
