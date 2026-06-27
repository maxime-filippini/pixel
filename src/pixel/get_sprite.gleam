// https://sprites.dev/api/sprites#get

import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/result
import pixel.{type SpriteCredentials}
import pixel/internal
import pixel/types.{type Sprite}

pub type GetSpriteResult {
  Found(sprite: Sprite)
  NotFound
}

pub type RequestBuilder {
  RequestBuilder(name: String)
}

pub fn request(sprite_name name: String) -> RequestBuilder {
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
    path: "/sprites/" <> builder.name,
    query: [],
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(GetSpriteResult, pixel.Error) {
  case resp.status {
    404 -> Ok(NotFound)
    401 -> Error(pixel.MissingAuthenticationError)
    200 -> {
      use sprite <- result.try(
        json.parse_bits(resp.body, types.sprite_decoder())
        |> result.map_error(pixel.BodyDecodeError(_, got: resp.body)),
      )

      Ok(Found(sprite))
    }
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
