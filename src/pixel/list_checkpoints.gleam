// https://sprites.dev/api/sprites/checkpoints#list-checkpoints

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
  Outcome(checkpoints: List(types.SpriteCheckpoint))
}

pub type RequestBuilder {
  RequestBuilder(name: String)
}

pub fn request(name: String) -> RequestBuilder {
  RequestBuilder(name:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  internal.request(
    credentials:,
    method: http.Get,
    headers: [],
    body: <<>>,
    path: "/sprites/" <> builder.name <> "/checkpoints",
    query: [],
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  let decoder = decode.list(types.checkpoint_decoder())

  case resp.status {
    200 -> {
      use checkpoints <- result.try(
        json.parse_bits(resp.body, decoder)
        |> result.map_error(pixel.BodyDecodeError(_, resp.body)),
      )

      Ok(Outcome(checkpoints))
    }
    404 -> Error(pixel.ResourceNotFound)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
