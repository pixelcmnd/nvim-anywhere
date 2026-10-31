REAL_NVIM=$(command -v nvim || true)
export REAL_NVIM
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
setup_fake_bin() {
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp" FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$TMPDIR" "$FAKE_BIN"
  export PATH="$FAKE_BIN:/usr/bin:/bin"
  make_stub osascript 'case "$1" in *current_app.scpt) echo 123 ;; esac'
  make_stub pbcopy 'cat > "$HOME/clipboard"'
  make_stub xclip 'cat > "$HOME/clipboard"'
  make_stub nvim 'exit 0'
}
make_stub() {
  printf '#!/bin/bash\n%s\n' "${2:-true}" > "$FAKE_BIN/$1"
  chmod +x "$FAKE_BIN/$1"
}
run_script() {
  local os=$1 script=$2
  run /bin/bash -c 'OSTYPE=$1; source "$2"' _ "$os" "$script"
}
