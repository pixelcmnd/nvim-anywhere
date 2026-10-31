#!/usr/bin/env bats
load helpers
setup() {
  setup_fake_bin
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  origin="$BATS_TEST_TMPDIR/origin"
  mkdir -p "$origin/VimAnywhere.workflow/Contents" "$HOME/Library/Services"
  git -C "$origin" init -q
  printf old > "$origin/VimAnywhere.workflow/Contents/version"
  git -C "$origin" add .
  git -C "$origin" -c user.name=Test -c user.email=test@example.com commit -qm old
  git clone -q "$origin" "$HOME/.vim-anywhere"
  cp -R "$HOME/.vim-anywhere/VimAnywhere.workflow" "$HOME/Library/Services/VimAnywhere.workflow"
  old_head=$(git -C "$HOME/.vim-anywhere" rev-parse HEAD)
  printf new > "$origin/VimAnywhere.workflow/Contents/version"
  git -C "$origin" add .
  git -C "$origin" -c user.name=Test -c user.email=test@example.com commit -qm new
}
@test "update installs the new checkout and workflow" {
  run_script darwin "$REPO_ROOT/update"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.vim-anywhere/VimAnywhere.workflow/Contents/version")" = new ]
  [ "$(cat "$HOME/Library/Services/VimAnywhere.workflow/Contents/version")" = new ]
}
@test "workflow replacement failure restores checkout and workflow" {
  make_stub mv 'case "$1" in */next.workflow) exit 1 ;; esac; exec /bin/mv "$@"'
  run_script darwin "$REPO_ROOT/update"
  [ "$status" -ne 0 ]
  [ "$(git -C "$HOME/.vim-anywhere" rev-parse HEAD)" = "$old_head" ]
  [ "$(cat "$HOME/Library/Services/VimAnywhere.workflow/Contents/version")" = old ]
}
