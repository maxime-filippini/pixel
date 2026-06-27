import gleam/dynamic/decode
import gleam/option.{None}
import gleam/time/timestamp
import pixel/decoders

pub type SpriteStatus {
  Cold
  Warm
  Running
}

pub type SpriteAuth {
  SpriteAuth
  PublicAuth
}

pub type CheckpointHealth {
  Healthy
  Unhealthy
}

pub type SpriteCheckpoint {
  SpriteCheckpoint(
    id: String,
    create_time: timestamp.Timestamp,
    source_id: option.Option(String),
    comment: option.Option(String),
    health: CheckpointHealth,
  )
}

pub type SpriteUrlSettings {
  SpriteUrlSettings(auth: SpriteAuth, private_access: String)
}

pub type Sprite {
  Sprite(
    id: String,
    name: String,
    status: SpriteStatus,
    url: String,
    url_settings: SpriteUrlSettings,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
    last_started_at: option.Option(timestamp.Timestamp),
    last_active_at: option.Option(timestamp.Timestamp),
  )
}

pub fn sprite_decoder() {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use status <- decode.field("status", sprite_status_decoder())

  use url <- decode.field("url", decode.string)
  use url_settings <- decode.field(
    "url_settings",
    sprite_url_settings_decoder(),
  )
  use created_at <- decode.field("created_at", decoders.timestamp_decoder())
  use updated_at <- decode.field("updated_at", decoders.timestamp_decoder())
  use last_started_at <- decode.optional_field(
    "last_started_at",
    option.None,
    decode.optional(decoders.timestamp_decoder()),
  )
  use last_active_at <- decode.optional_field(
    "last_active_at",
    option.None,
    decode.optional(decoders.timestamp_decoder()),
  )

  decode.success(Sprite(
    id:,
    name:,
    status:,
    url:,
    url_settings:,
    created_at:,
    updated_at:,
    last_started_at:,
    last_active_at:,
  ))
}

pub fn sprite_url_settings_decoder() {
  use auth <- decode.field("auth", sprite_auth_decoder())
  use private_access <- decode.field("private_access", decode.string)
  decode.success(SpriteUrlSettings(auth:, private_access:))
}

pub fn sprite_status_decoder() {
  use variant <- decode.then(decode.string)
  case variant {
    "cold" -> decode.success(Cold)
    "warm" -> decode.success(Warm)
    "running" -> decode.success(Running)
    _ -> decode.failure(Cold, "cold, warm or running")
  }
}

pub fn sprite_auth_decoder() {
  use variant <- decode.then(decode.string)
  case variant {
    "sprite" -> decode.success(SpriteAuth)
    "public" -> decode.success(PublicAuth)
    _ -> decode.failure(SpriteAuth, "sprite or public")
  }
}

pub fn auth_to_string(auth: SpriteAuth) {
  case auth {
    SpriteAuth -> "sprite"
    PublicAuth -> "public"
  }
}

pub fn health_decoder() {
  use v <- decode.then(decode.string)
  case v {
    "mount_failed" -> decode.success(Unhealthy)
    _ -> decode.failure(Unhealthy, "within [mount_failed]")
  }
}

pub fn checkpoint_decoder() {
  use id <- decode.field("id", decode.string)
  use create_time <- decode.field("create_time", decoders.timestamp_decoder())
  use source_id <- decode.optional_field(
    "source_id",
    None,
    decode.optional(decode.string),
  )
  use comment <- decode.optional_field(
    "comment",
    None,
    decode.optional(decode.string),
  )

  use health <- decode.optional_field("health", Healthy, health_decoder())

  decode.success(SpriteCheckpoint(
    id:,
    create_time:,
    source_id:,
    comment:,
    health:,
  ))
}

pub type FileSystemEntryType {
  File
  Dir
}

pub type FileSystemEntry {
  FileSystemEntry(
    name: String,
    path: String,
    type_: FileSystemEntryType,
    size: Int,
    mode: String,
    modified_time: timestamp.Timestamp,
    is_directory: Bool,
  )
}

fn file_system_entry_type_decoder() -> decode.Decoder(FileSystemEntryType) {
  use variant <- decode.then(decode.string)
  case variant {
    "file" -> decode.success(File)
    "dir" -> decode.success(Dir)
    _ -> decode.failure(File, "FileSystemEntryType")
  }
}

pub fn file_system_entry_decoder() -> decode.Decoder(FileSystemEntry) {
  use name <- decode.field("name", decode.string)
  use path <- decode.field("path", decode.string)
  use type_ <- decode.field("type_", file_system_entry_type_decoder())
  use size <- decode.field("size", decode.int)
  use mode <- decode.field("mode", decode.string)
  use modified_time <- decode.field(
    "modified_time",
    decoders.timestamp_decoder(),
  )
  use is_directory <- decode.field("is_directory", decode.bool)
  decode.success(FileSystemEntry(
    name:,
    path:,
    type_:,
    size:,
    mode:,
    modified_time:,
    is_directory:,
  ))
}

pub type Octal {
  O0
  O1
  O2
  O3
  O4
  O5
  O6
  O7
}

pub type UserPermission {
  UserPermission(r: Bool, w: Bool, x: Bool)
}

pub type FilePermission {
  FilePermission(
    owner: UserPermission,
    group: UserPermission,
    others: UserPermission,
  )
}

fn octal_to_string(o: Octal) -> String {
  case o {
    O0 -> "0"
    O1 -> "1"
    O2 -> "2"
    O3 -> "3"
    O5 -> "5"
    O4 -> "4"
    O6 -> "6"
    O7 -> "7"
  }
}

fn user_permission_to_octal(op: UserPermission) -> Octal {
  case op.r, op.w, op.x {
    True, True, True -> O7
    True, True, False -> O6
    True, False, True -> O5
    True, False, False -> O4
    False, True, True -> O3
    False, True, False -> O2
    False, False, True -> O1
    False, False, False -> O0
  }
}

pub fn file_permission_to_string(fp: FilePermission) -> String {
  let owner_digit = user_permission_to_octal(fp.owner)
  let group_digit = user_permission_to_octal(fp.group)
  let others_digit = user_permission_to_octal(fp.others)

  octal_to_string(owner_digit)
  <> octal_to_string(group_digit)
  <> octal_to_string(others_digit)
}

pub fn permission_644() -> FilePermission {
  FilePermission(
    owner: UserPermission(r: True, w: True, x: False),
    group: UserPermission(r: True, w: False, x: False),
    others: UserPermission(r: True, w: False, x: False),
  )
}
