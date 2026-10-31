#!/usr/bin/env bats
load helpers
setup() { setup_fake_bin; make_stub neovide; make_stub gvim; make_stub gsettings; }
@test "installation preserves previous data and configuration" {
  mkdir -p "$HOME/.vim-anywhere" "$HOME/.config/vim-anywhere"
  echo old > "$HOME/.vim-anywhere/user-data"
  echo editor=neovide > "$HOME/.config/vim-anywhere/config"
  run_script darwin "$REPO_ROOT/install"
  [ "$status" -eq 0 ]; [ -f "$HOME/.vim-anywhere/bin/run" ]
  [ -f "$HOME/.config/vim-anywhere/config" ]
  backups=("$HOME"/.vim-anywhere-backup.*); [ -f "${backups[0]}/user-data" ]
}
@test "missing editor leaves installation intact" {
  mkdir -p "$HOME/.vim-anywhere"; echo keep > "$HOME/.vim-anywhere/data"
  export VIM_ANYWHERE_EDITOR=/nonexistent/editor
  run_script darwin "$REPO_ROOT/install"
  [ "$status" -ne 0 ]; [ -f "$HOME/.vim-anywhere/data" ]
}
@test "Linux installation succeeds" {
  run_script linux-gnu "$REPO_ROOT/install"
  [ "$status" -eq 0 ]; [ -f "$HOME/.vim-anywhere/bin/run" ]
}
@test "reinstallation keeps previous installation" {
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  echo custom > "$HOME/.vim-anywhere/local-data"
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  backups=("$HOME"/.vim-anywhere-backup.*); [ -f "${backups[0]}/local-data" ]
}
@test "update refuses local changes without discarding them" {
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  echo custom > "$HOME/.vim-anywhere/local-data"
  run_script darwin "$HOME/.vim-anywhere/update"
  [ "$status" -ne 0 ]; [ -f "$HOME/.vim-anywhere/local-data" ]
}
