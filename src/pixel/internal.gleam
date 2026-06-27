import gleam/http
import gleam/http/request
import gleam/list
import gleam/option.{None, Some}
import gleam/uri
import pixel

pub fn request(
  credentials credentials: pixel.SpriteCredentials,
  method method: http.Method,
  headers headers: List(#(String, String)),
  body body: a,
  path path: String,
  query query: List(#(String, String)),
) {
  let query = case uri.query_to_string(query) {
    "" -> None
    v -> Some(v)
  }

  let headers =
    list.prepend(headers, #("authorization", "Bearer " <> credentials.token))

  request.Request(
    method:,
    headers:,
    // todo: maybe parametrize the api version
    path: "v1" <> path,
    query:,
    body:,
    scheme: http.Https,
    host: "api.sprites.dev",
    port: option.None,
  )
}
