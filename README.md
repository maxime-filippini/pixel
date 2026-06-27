# pixel

A client library for fly.io's [Sprites API](https://sprites.dev/api/sprites).

This library is built "sans-IO", which means it provides constructors for
API requests and parsers for responses. Users will have to plug in their own
HTTP client.

Here is an example of usage with `gleam_httpc`:

```gleam
import gleam/httpc
import gleam/result

import pixel
import pixel/create_sprite

pub type Sprite {
  Sprite(id: String, name: String)
}

/// Create a sprite using `pixel`
pub fn create_sprite(
  creds: pixel.SpriteCredentials,
  name: String,
) -> Sprite {
  // Build the request
  let request =
    create_sprite.request(sprite_name: name)
    |> create_sprite.build(creds)

  // Send the request
  let assert Ok(resp) = httpc.send_bits(request)
  
  // Parse the response
  let assert Ok(output) = create_sprite.response(resp)

  // Use the parsed response
  Sprite(id: output.id, name: output.name)
}
```