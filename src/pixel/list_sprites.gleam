// https://sprites.dev/api/sprites#list

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import pixel

import pixel/internal
import pixel/types.{type Sprite}

pub type ListSpritesResult {
  ListSpritesResult(sprites: List(Sprite))
}

pub opaque type MaxResults {
  MaxResults(inner: Int)
}

/// Valid range: 1-50 (clamp is applied)
pub fn max_results(n: Int) -> MaxResults {
  case n {
    x if x < 1 -> MaxResults(1)
    x if x <= 50 -> MaxResults(x)
    _ -> MaxResults(50)
  }
}

pub type RequestBuilder {
  RequestBuilder(
    prefix: option.Option(String),
    max_results: option.Option(MaxResults),
    continuation_token: option.Option(String),
  )
}

pub fn request() -> RequestBuilder {
  RequestBuilder(prefix: None, max_results: None, continuation_token: None)
}

pub fn with_prefix(builder: RequestBuilder, s: String) -> RequestBuilder {
  RequestBuilder(..builder, prefix: Some(s))
}

pub fn with_continuation_token(
  builder: RequestBuilder,
  s: String,
) -> RequestBuilder {
  RequestBuilder(..builder, continuation_token: Some(s))
}

pub fn with_max_results(
  builder: RequestBuilder,
  max_results: MaxResults,
) -> RequestBuilder {
  RequestBuilder(..builder, max_results: Some(max_results))
}

fn prepend_if_some(lst: List(b), opt: Option(a), f: fn(a) -> b) -> List(b) {
  case opt {
    Some(v) -> list.prepend(lst, f(v))
    None -> lst
  }
}

pub fn build(
  builder: RequestBuilder,
  credentials: pixel.SpriteCredentials,
) -> request.Request(BitArray) {
  let query =
    []
    |> prepend_if_some(builder.prefix, fn(v) { #("prefix", v) })
    |> prepend_if_some(builder.continuation_token, fn(v) {
      #("continuatin_token", v)
    })
    |> prepend_if_some(builder.max_results, fn(v) {
      #("max_results", int.to_string(v.inner))
    })

  internal.request(
    credentials:,
    method: http.Get,
    body: <<>>,
    path: "/sprites",
    headers: [],
    query:,
  )
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(ListSpritesResult, pixel.Error) {
  case resp.status {
    200 -> {
      let body_decoder = {
        use sprites <- decode.field(
          "sprites",
          decode.list(types.sprite_decoder()),
        )
        decode.success(ListSpritesResult(sprites:))
      }

      use body <- result.try(
        json.parse_bits(resp.body, body_decoder)
        |> result.map_error(pixel.BodyDecodeError(_, got: resp.body)),
      )

      Ok(body)
    }
    401 -> Error(pixel.MissingAuthenticationError)
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
