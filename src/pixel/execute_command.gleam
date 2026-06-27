// https://sprites.dev/api/sprites/exec#execute-command-post

import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import pixel.{type SpriteCredentials}
import pixel/internal

pub type Outcome {
  Outcome(exit_code: Int, stdout: BitArray)
}

pub type RequestBuilder {
  RequestBuilder(
    sprite_name: String,
    cmd: List(String),
    env: List(#(String, String)),
    dir: String,
    stdin: Option(BitArray),
  )
}

pub fn request(
  sprite_name sprite_name: String,
  cmd cmd: List(String),
  dir dir: String,
) -> RequestBuilder {
  RequestBuilder(sprite_name:, cmd:, dir:, env: [], stdin: None)
}

pub fn add_env(builder: RequestBuilder, key: String, value: String) {
  RequestBuilder(..builder, env: [#(key, value), ..builder.env])
}

pub fn with_stdin(builder: RequestBuilder, stdin: BitArray) {
  RequestBuilder(..builder, stdin: Some(stdin))
}

pub fn build(
  builder: RequestBuilder,
  credentials: SpriteCredentials,
) -> request.Request(BitArray) {
  let cmd_query = builder.cmd |> list.map(fn(c) { #("cmd", c) })
  let env_query =
    builder.env |> list.map(fn(pair) { #("env", pair.0 <> "=" <> pair.1) })

  let query =
    [
      #("dir", builder.dir),
    ]
    |> list.append(cmd_query)
    |> list.append(env_query)
    |> list.prepend(
      #("stdin", case builder.stdin {
        Some(_) -> "true"
        None -> "false"
      }),
    )

  let body = case builder.stdin {
    Some(v) -> v
    None -> <<>>
  }

  internal.request(
    credentials:,
    method: http.Post,
    headers: [],
    body: body,
    path: "/sprites/" <> builder.sprite_name <> "/exec",
    query: query,
  )
  |> echo
}

pub fn response(
  resp: response.Response(BitArray),
) -> Result(Outcome, pixel.Error) {
  case resp.status {
    400 -> Error(pixel.InvalidRequestParameters(resp))
    401 -> Error(pixel.MissingAuthenticationError)
    404 -> Error(pixel.SpriteNotFound)
    200 -> {
      use out <- result.try(parse_output(resp))
      Ok(Outcome(out.0, out.1))
    }
    _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}

pub fn parse_output(
  resp: response.Response(BitArray),
) -> Result(#(Int, BitArray), pixel.Error) {
  let size = bit_array.byte_size(resp.body)

  let payload = bit_array.slice(resp.body, 1, size - 3)
  let end_frame = bit_array.slice(resp.body, size - 2, 2)

  case payload, end_frame {
    Ok(payload), Ok(<<3, code>>) -> Ok(#(code, payload))
    _, _ -> Error(pixel.UnexpectedResponseError(resp))
  }
}
