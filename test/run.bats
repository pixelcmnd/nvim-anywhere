#!/usr/bin/env bats
load helpers
setup() { setup_fake_bin; make_stub neovide 'printf "%s\n" "$@" > "$HOME/args"; printf edited > "$3"'; }

@test "macOS defaults to blocking Neovide and copies after exit" {
  make_stub neovide 'printf "%s\n" "$@" > "$HOME/args"; printf edited > "$4"'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ "$(cat "$HOME/clipboard")" = edited ]
  grep -q -- --no-fork "$HOME/args"
  ! grep -q -- --nofork "$HOME/args"
}
@test "empty output is successful" {
  make_stub neovide 'true'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ ! -s "$HOME/clipboard" ]
}
@test "failure and cancellation preserve clipboard" {
  echo original > "$HOME/clipboard"
  make_stub neovide 'exit 9'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 9 ]; [ "$(cat "$HOME/clipboard")" = original ]
  make_stub neovide 'touch "$VIM_ANYWHERE_CANCEL_FILE"'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -ne 0 ]; [ "$(cat "$HOME/clipboard")" = original ]
}
@test "custom path containing spaces and explicit override" {
  mkdir -p "$HOME/my editors" "$HOME/.config/vim-anywhere"
  printf 'editor=missing\n' > "$HOME/.config/vim-anywhere/config"
  printf '#!/bin/bash\nprintf custom > "$1"\n' > "$HOME/my editors/editor"
  chmod +x "$HOME/my editors/editor"
  export VIM_ANYWHERE_EDITOR="$HOME/my editors/editor"
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ "$(cat "$HOME/clipboard")" = custom ]
}
@test "missing editor is reported" {
  export VIM_ANYWHERE_EDITOR=/nonexistent/editor
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -ne 0 ]; [[ "$output" == *'editor executable not found'* ]]
}
@test "Linux uses gvim flags and xclip" {
  make_stub gvim 'printf "%s\n" "$@" > "$HOME/args"; printf linux > "${@: -1}"'
  run_script linux-gnu "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ "$(cat "$HOME/clipboard")" = linux ]
  grep -q -- --nofork "$HOME/args"
}
@test "sessions create unique private history files" {
  make_stub neovide 'true'
  run_script darwin "$REPO_ROOT/bin/run"; [ "$status" -eq 0 ]
  run_script darwin "$REPO_ROOT/bin/run"; [ "$status" -eq 0 ]
  dir="$TMPDIR/vim-anywhere-$UID"
  [ "$(find "$dir" -type f | wc -l | tr -d ' ')" = 2 ]
  [ -z "$(find "$dir" -type f -perm -077 -print)" ]
}
@test "concurrent sessions wait before copying and use different files" {
  make_stub neovide 'echo "$4" >> "$HOME/files"; while [ ! -e "$HOME/release" ]; do sleep 0.05; done; printf complete > "$4"'
  echo old > "$HOME/clipboard"
  /bin/bash -c 'OSTYPE=darwin; source "$1"' _ "$REPO_ROOT/bin/run" &
  p1=$!
  /bin/bash -c 'OSTYPE=darwin; source "$1"' _ "$REPO_ROOT/bin/run" &
  p2=$!
  for ((i=0; i<100; i++)); do [ -f "$HOME/files" ] && [ "$(wc -l < "$HOME/files" | tr -d ' ')" = 2 ] && break; sleep 0.05; done
  [ "$(cat "$HOME/clipboard")" = old ]
  [ "$(sort -u "$HOME/files" | wc -l | tr -d ' ')" = 2 ]
  touch "$HOME/release"
  wait "$p1"; wait "$p2"
  [ "$(cat "$HOME/clipboard")" = complete ]
}
@test "macOS focus restoration runs after editor failure" {
  make_stub osascript 'case "$1" in *current_app.scpt) echo 123 ;; *restore_app.scpt) echo restored > "$HOME/restored" ;; esac'
  make_stub neovide 'exit 4'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 4 ]; [ -f "$HOME/restored" ]
}

@test "actual Neovim cancellation command creates marker even with spaces" {
  [ -n "$REAL_NVIM" ] || skip "Neovim is unavailable"
  export TMPDIR="$BATS_TEST_TMPDIR/temp with spaces"
  mkdir -p "$TMPDIR"
  echo original > "$HOME/clipboard"
  make_stub neovide '"$REAL_NVIM" --headless -u NONE -i NONE -c "$7" -c VimAnywhereCancel; exit 0'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -ne 0 ]; [ "$(cat "$HOME/clipboard")" = original ]
  [ -n "$(find "$TMPDIR" -name "*.cancel" -print)" ]
}
@test "q! cancels without copying, while q and wq complete" {
  [ -n "$REAL_NVIM" ] || skip "Neovim is unavailable"
  make_stub neovide '"$REAL_NVIM" --headless -u NONE -i NONE "$4" -c "$7" -c "call feedkeys(\":$TEST_QUIT\\<CR>\", \"xt\")"'
  echo original > "$HOME/clipboard"
  export TEST_QUIT='q!'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -ne 0 ]; [ "$(cat "$HOME/clipboard")" = original ]
  export TEST_QUIT=q
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ ! -s "$HOME/clipboard" ]
  export TEST_QUIT=wq
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]
}
@test "q! closing a split does not cancel a later successful exit" {
  [ -n "$REAL_NVIM" ] || skip "Neovim is unavailable"
  make_stub neovide '"$REAL_NVIM" --headless -u NONE -i NONE "$4" -c "$7" -c "vsplit" -c "call feedkeys(\":q!\\<CR>:wq\\<CR>\", \"xt\")"'
  run_script darwin "$REPO_ROOT/bin/run"
  [ "$status" -eq 0 ]; [ -f "$HOME/clipboard" ]
}
