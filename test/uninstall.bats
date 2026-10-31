#!/usr/bin/env bats
load helpers
setup() { setup_fake_bin; }
@test "uninstall preserves configuration and history" {
  mkdir -p "$HOME/.nvim-anywhere/bin" "$HOME/.config/nvim-anywhere" "$TMPDIR/nvim-anywhere-$UID"
  touch "$HOME/.nvim-anywhere/bin/run" "$HOME/.nvim-anywhere/uninstall" "$HOME/.config/nvim-anywhere/config" "$TMPDIR/nvim-anywhere-$UID/doc"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -eq 0 ]; [ ! -e "$HOME/.nvim-anywhere" ]
  backups=("$HOME"/.nvim-anywhere-uninstalled.*); [ -f "${backups[0]}/bin/run" ]
  [ -f "$HOME/.config/nvim-anywhere/config" ]; [ -f "$TMPDIR/nvim-anywhere-$UID/doc" ]
}
@test "uninstall refuses unrecognized directory" {
  mkdir -p "$HOME/.nvim-anywhere"; touch "$HOME/.nvim-anywhere/important"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -ne 0 ]; [ -f "$HOME/.nvim-anywhere/important" ]
}

@test "uninstall preserves files and local edits inside installation" {
  mkdir -p "$HOME/.nvim-anywhere/bin"
  printf modified > "$HOME/.nvim-anywhere/bin/run"
  touch "$HOME/.nvim-anywhere/uninstall" "$HOME/.nvim-anywhere/user-data"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -eq 0 ]; [ ! -e "$HOME/.nvim-anywhere" ]
  backups=("$HOME"/.nvim-anywhere-uninstalled.*)
  [ "$(cat "${backups[0]}/bin/run")" = modified ]; [ -f "${backups[0]}/user-data" ]
}
