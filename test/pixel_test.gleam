import gleam/bit_array
import gleam/http.{Get, Post}
import gleam/http/response
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import pixel
import pixel/create_sprite
import pixel/execute_command
import pixel/get_sprite
import pixel/list_sprites
import pixel/read_file
import pixel/types

pub fn main() -> Nil {
  gleeunit.main()
}

fn credentials() {
  pixel.credentials(org: "fly", token: "secret-token")
}

fn json_response(status: Int, body: String) {
  response.Response(
    status: status,
    headers: [],
    body: bit_array.from_string(body),
  )
}

pub fn get_sprite_builds_authenticated_request_test() {
  let req =
    get_sprite.request(sprite_name: "demo")
    |> get_sprite.build(credentials())

  assert req.method == Get
  assert req.host == "api.sprites.dev"
  assert req.path == "v1/sprites/demo"
  assert req.query == None
  assert req.headers == [#("authorization", "Bearer secret-token")]
}

pub fn create_sprite_builds_json_body_test() {
  let req =
    create_sprite.request(sprite_name: "demo")
    |> create_sprite.with_auth(types.PublicAuth)
    |> create_sprite.build(credentials())

  let assert Ok(body) = bit_array.to_string(req.body)

  assert req.method == Post
  assert req.path == "v1/sprites"
  assert req.headers
    == [
      #("authorization", "Bearer secret-token"),
      #("content-type", "application/json"),
    ]
  assert body
    == json.object([
      #("name", json.string("demo")),
      #("url_settings", json.object([#("auth", json.string("public"))])),
    ])
    |> json.to_string
}

pub fn list_sprites_builds_expected_query_test() {
  let req =
    list_sprites.request()
    |> list_sprites.with_prefix("prod")
    |> list_sprites.with_continuation_token("next-page")
    |> list_sprites.with_max_results(list_sprites.max_results(999))
    |> list_sprites.build(credentials())

  assert req.method == Get
  assert req.path == "v1/sprites"
  assert req.query
    == Some("max_results=50&continuation_token=next-page&prefix=prod")
}

pub fn read_file_builds_expected_query_test() {
  let req =
    read_file.request(
      sprite_name: "demo",
      path: "file.txt",
      working_directory: "workspace",
    )
    |> read_file.build(credentials())

  assert req.method == Get
  assert req.path == "v1/sprites/demo/fs/read"
  assert req.query == Some("path=file.txt&workingDir=workspace")
}

pub fn list_sprites_response_decodes_sprites_test() {
  let body =
    "{\"sprites\":[{\"id\":\"spr_123\",\"name\":\"demo\",\"status\":\"running\",\"url\":\"https://demo.sprites.dev\",\"url_settings\":{\"auth\":\"public\",\"private_access\":\"off\"},\"created_at\":\"2026-01-01T00:00:00Z\",\"updated_at\":\"2026-01-01T00:01:00Z\",\"last_started_at\":null}]}"

  let assert Ok(list_sprites.ListSpritesResult(sprites: [sprite])) =
    list_sprites.response(json_response(200, body))

  assert sprite.id == "spr_123"
  assert sprite.name == "demo"
  assert sprite.status == types.Running
  assert sprite.url_settings.auth == types.PublicAuth
  assert sprite.last_started_at == None
  assert sprite.last_active_at == None
}

pub fn file_permission_to_string_test() {
  let executable =
    types.FilePermission(
      owner: types.UserPermission(r: True, w: True, x: True),
      group: types.UserPermission(r: True, w: False, x: True),
      others: types.UserPermission(r: False, w: False, x: True),
    )

  assert types.file_permission_to_string(types.permission_644()) == "644"
  assert types.file_permission_to_string(executable) == "751"
}

pub fn execute_command_parse_output_test() {
  let resp =
    response.Response(status: 200, headers: [], body: <<1, 111, 107, 3, 7>>)

  let assert Ok(#(exit_code, stdout)) = execute_command.parse_output(resp)

  assert exit_code == 7
  assert stdout == bit_array.from_string("ok")
}
