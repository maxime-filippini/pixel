// https://sprites.dev/api/sprites/checkpoints#restore-checkpoint

import gleam/http
import gleam/http/request
import gleam/http/response

import pixel.{type SpriteCredentials}
import pixel/internal

pub type Outcome {
  Restored
  NotFound
}

pub type RequestBuilder {
  RequestBuilder(sprite_name: String, checkpoint_id: String)
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
      <> builder.checkpoint_id
      <> "/restore",
    query: [],
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    200 -> Ok(Restored)
    404 -> Ok(NotFound)
    401 -> Error(pixel.MissingAuthenticationError)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
