#!/usr/bin/env bats
load helpers
setup() { setup_fake_bin; make_stub neovide; make_stub gvim; make_stub gsettings; }
@test "installation preserves previous data and configuration" {
  mkdir -p "$HOME/.nvim-anywhere" "$HOME/.config/nvim-anywhere"
  echo old > "$HOME/.nvim-anywhere/user-data"
  echo editor=neovide > "$HOME/.config/nvim-anywhere/config"
  run_script darwin "$REPO_ROOT/install"
  [ "$status" -eq 0 ]; [ -f "$HOME/.nvim-anywhere/bin/run" ]
  [ -f "$HOME/.config/nvim-anywhere/config" ]
  backups=("$HOME"/.nvim-anywhere-backup.*); [ -f "${backups[0]}/user-data" ]
}
@test "missing editor leaves installation intact" {
  mkdir -p "$HOME/.nvim-anywhere"; echo keep > "$HOME/.nvim-anywhere/data"
  export NVIM_ANYWHERE_EDITOR=/nonexistent/editor
  run_script darwin "$REPO_ROOT/install"
  [ "$status" -ne 0 ]; [ -f "$HOME/.nvim-anywhere/data" ]
}
@test "Linux installation succeeds" {
  run_script linux-gnu "$REPO_ROOT/install"
  [ "$status" -eq 0 ]; [ -f "$HOME/.nvim-anywhere/bin/run" ]
}
@test "reinstallation keeps previous installation" {
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  echo custom > "$HOME/.nvim-anywhere/local-data"
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  backups=("$HOME"/.nvim-anywhere-backup.*); [ -f "${backups[0]}/local-data" ]
}
@test "update refuses local changes without discarding them" {
  run_script darwin "$REPO_ROOT/install"; [ "$status" -eq 0 ]
  echo custom > "$HOME/.nvim-anywhere/local-data"
  run_script darwin "$HOME/.nvim-anywhere/update"
  [ "$status" -ne 0 ]; [ -f "$HOME/.nvim-anywhere/local-data" ]
}
@test "install leaves old installation and workflow intact" {
  mkdir -p "$HOME/.vim-anywhere" "$HOME/Library/Services/VimAnywhere.workflow"
  touch "$HOME/.vim-anywhere/data" "$HOME/Library/Services/VimAnywhere.workflow/old"
  run_script darwin "$REPO_ROOT/install"
  [ "$status" -eq 0 ]; [ -f "$HOME/.vim-anywhere/data" ]
  [ -f "$HOME/Library/Services/VimAnywhere.workflow/old" ]
  [ -f "$HOME/Library/Services/NvimAnywhere.workflow/Contents/document.wflow" ]
  [[ "$output" == *'old VimAnywhere service'* ]]
}
