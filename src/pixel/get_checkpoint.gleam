// https://sprites.dev/api/sprites/checkpoints#get-checkpoint

import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/result
import gleam/string

import pixel.{type SpriteCredentials}
import pixel/internal
import pixel/types

pub type RequestBuilder {
  RequestBuilder(sprite_name: String, checkpoint_id: String)
}

pub type Outcome {
  Found(types.SpriteCheckpoint)
  NotFound
}

pub fn request(
  sprite_name sprite_name: String,
  checkpoint_id checkpoint_id: String,
) -> RequestBuilder {
  RequestBuilder(sprite_name:, checkpoint_id:)
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
    path: "/sprites/"
      <> builder.sprite_name
      <> "/checkpoints/"
      <> builder.checkpoint_id,
    query: [],
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    401 -> Error(pixel.MissingAuthenticationError)
    200 -> {
      use out <- result.try(
        json.parse_bits(resp.body, types.checkpoint_decoder())
        |> result.map_error(pixel.BodyDecodeError(_, resp.body)),
      )

      Ok(Found(out))
    }
    _ -> {
      use body_str <- result.try(
        bit_array.to_string(resp.body)
        |> result.map_error(fn(_) { pixel.ResponseEncodingError(resp.body) }),
      )

      let check =
        body_str
        |> string.contains("checkpoint not found")

      case check, resp.status {
        True, _ -> Ok(NotFound)
        False, 404 -> Error(pixel.SpriteNotFound)
        False, _ -> Error(pixel.UnexpectedResponseError(resp))
      }
    }
  }
}
