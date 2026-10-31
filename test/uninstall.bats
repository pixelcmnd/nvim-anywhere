#!/usr/bin/env bats
load helpers
setup() { setup_fake_bin; }
@test "uninstall preserves configuration and history" {
  mkdir -p "$HOME/.vim-anywhere/bin" "$HOME/.config/vim-anywhere" "$TMPDIR/vim-anywhere-$UID"
  touch "$HOME/.vim-anywhere/bin/run" "$HOME/.vim-anywhere/uninstall" "$HOME/.config/vim-anywhere/config" "$TMPDIR/vim-anywhere-$UID/doc"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -eq 0 ]; [ ! -e "$HOME/.vim-anywhere" ]
  backups=("$HOME"/.vim-anywhere-uninstalled.*); [ -f "${backups[0]}/bin/run" ]
  [ -f "$HOME/.config/vim-anywhere/config" ]; [ -f "$TMPDIR/vim-anywhere-$UID/doc" ]
}
@test "uninstall refuses unrecognized directory" {
  mkdir -p "$HOME/.vim-anywhere"; touch "$HOME/.vim-anywhere/important"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -ne 0 ]; [ -f "$HOME/.vim-anywhere/important" ]
}

@test "uninstall preserves files and local edits inside installation" {
  mkdir -p "$HOME/.vim-anywhere/bin"
  printf modified > "$HOME/.vim-anywhere/bin/run"
  touch "$HOME/.vim-anywhere/uninstall" "$HOME/.vim-anywhere/user-data"
  run_script darwin "$REPO_ROOT/uninstall"
  [ "$status" -eq 0 ]; [ ! -e "$HOME/.vim-anywhere" ]
  backups=("$HOME"/.vim-anywhere-uninstalled.*)
  [ "$(cat "${backups[0]}/bin/run")" = modified ]; [ -f "${backups[0]}/user-data" ]
}
