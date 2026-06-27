// https://sprites.dev/api/sprites#create

import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import gleam/time/timestamp
import pixel
import pixel/decoders

import pixel/internal
import pixel/types

pub type UrlSettings {
  UrlSettings(auth: types.SpriteAuth)
}

pub type CreateSpritesResult {
  CreateSpritesResult(
    id: String,
    name: String,
    organization: String,
    url: String,
    url_settings: UrlSettings,
    status: types.SpriteStatus,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
    last_started_at: Option(timestamp.Timestamp),
    last_active_at: Option(timestamp.Timestamp),
  )
}

pub type RequestBuilder {
  RequestBuilder(sprite_name: String, auth: types.SpriteAuth)
}

pub fn request(sprite_name sprite_name: String) -> RequestBuilder {
  RequestBuilder(sprite_name:, auth: types.SpriteAuth)
}

pub fn with_auth(builder: RequestBuilder, auth: types.SpriteAuth) {
  RequestBuilder(..builder, auth:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: pixel.SpriteCredentials,
) -> request.Request(BitArray) {
  let query = []

  let body =
    json.object([
      #("name", json.string(builder.sprite_name)),
      #(
        "url_settings",
        json.object([#("auth", json.string(types.auth_to_string(builder.auth)))]),
      ),
    ])
    |> json.to_string
    |> bit_array.from_string

  internal.request(
    credentials:,
    method: http.Post,
    body: body,
    path: "/sprites",
    headers: [#("content-type", "application/json")],
    query:,
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(CreateSpritesResult, pixel.Error) {
  case resp.status {
    201 -> {
      use body <- result.try(
        json.parse_bits(resp.body, decoder())
        |> result.map_error(pixel.BodyDecodeError(_, got: resp.body)),
      )

      Ok(body)
    }
    400 -> Error(pixel.InvalidRequestParameters(resp))
    401 -> Error(pixel.MissingAuthenticationError)
    409 -> Error(pixel.SpriteAlreadyExists)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}

fn decoder() {
  let url_settings_decoder = {
    use auth <- decode.field("auth", types.sprite_auth_decoder())
    decode.success(UrlSettings(auth:))
  }

  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use organization <- decode.field("organization", decode.string)
  use url <- decode.field("url", decode.string)
  use status <- decode.field("status", types.sprite_status_decoder())
  use url_settings <- decode.field("url_settings", url_settings_decoder)
  use created_at <- decode.field("created_at", decoders.timestamp_decoder())
  use updated_at <- decode.field("updated_at", decoders.timestamp_decoder())
  use last_started_at <- decode.optional_field(
    "last_started_at",
    None,
    decode.optional(decoders.timestamp_decoder()),
  )
  use last_active_at <- decode.optional_field(
    "last_active_at",
    None,
    decode.optional(decoders.timestamp_decoder()),
  )

  decode.success(CreateSpritesResult(
    id:,
    name:,
    organization:,
    url:,
    status:,
    url_settings:,
    created_at:,
    updated_at:,
    last_active_at:,
    last_started_at:,
  ))
}
