# vim-anywhere

Invoke a GUI Vim editor from another application, edit a private temporary file,
and return its contents to the clipboard. Focus returns to the original macOS
application; paste manually with Command-V. Linux uses gVim and xclip.

## Installation

On macOS install Neovide and a compatible Neovim using your preferred package
manager. For example, with Nix and a configuration managed by Home Manager or
nix-darwin, add these packages to the appropriate package list:

```nix
# Home Manager: home.packages; nix-darwin: environment.systemPackages
[ pkgs.neovide pkgs.neovim ]
```

If you already manage Neovim separately, you only need to add `pkgs.neovide`.
Alternatively, install both in a Nix user profile:

```bash
nix profile install nixpkgs#neovide nixpkgs#neovim
```

Or, with Homebrew, use `brew install --cask neovide` and `brew install neovim`.
Check [Neovide's installation instructions](https://neovide.dev/installation.html)
for version requirements. Linux requires gVim, xclip and GNOME's gsettings or
legacy gconftool for automatic shortcut setup.

Clone **this fork**, enter its checkout, and run `./install`. The installer
copies the current checkout into `~/.vim-anywhere`, including local changes,
and preserves an existing installation and workflow in named backup directories.
It never downloads the original upstream repository. `~/.vim-anywhere/update`
fast-forwards the installed checkout from the local source checkout used for
installation; the source checkout must remain available. Local changes in the
installation must be resolved first. `~/.vim-anywhere/uninstall` removes the
shortcut workflow and moves the installation to a named backup; configuration,
backups and history remain.

On macOS enable VimAnywhere in System Settings > Keyboard > Keyboard Shortcuts
> Services (or Quick Actions), and assign Control-Command-V if available. The
installer does not replace existing service shortcuts. On Linux the GNOME
shortcut is Control-Alt-V. For i3 add `bindsym $mod+Alt+v exec ~/.vim-anywhere/bin/run`
to the i3 configuration and reload it.

## Editor and behavior

Neovide is the macOS default; gVim is the Linux default. Neovide launches your
normal Neovim configuration, including plugins and keymaps. No minimal Neovim
configuration is imposed. Neovide's `--no-fork` makes the process blocking and
an existing Neovide instance is not reused. A Neovide configuration specifying
`server` is incompatible with this session: use a local configuration without
that setting. `NEOVIDE_SERVER` is cleared for the session.

For persistent settings, create `~/.config/vim-anywhere/config` (or
`$XDG_CONFIG_HOME/vim-anywhere/config`) with simple, unquoted lines:

```text
editor=neovide
auto_paste=false
```

`editor` accepts `neovide`, `mvim`, `gvim`, or an absolute executable path.
An explicit `VIM_ANYWHERE_EDITOR` environment variable overrides the file;
the file overrides the platform default. A custom executable receives only the
file path and must stay in the foreground and return a nonzero status on failure.
Paths ending in the supported editor names receive their editor-specific options.
The scripts search the inherited `PATH`, `~/.nix-profile/bin`,
`/etc/profiles/per-user/$USER/bin`, `/run/current-system/sw/bin`, and common
Homebrew locations without reading shell startup files. For an editor in another
location, specify an absolute path. Neovide also needs `nvim` on that search
path; for a custom Nix profile, expose Neovim through one of those directories
or the environment inherited by the service. Prefer stable profile paths over
individual `/nix/store` paths, which change between generations. Legacy mvim and gvim retain support for `~/.gvimrc.min` or
`~/.vimrc.min`; Neovide does not use them.

Save and exit with `:wq`. A normal `:q` also completes successfully, including
an empty file. To cancel reliably in Neovide, MacVim or gVim, use
`:VimAnywhereCancel` or exit with `:q!`; the clipboard is left unchanged.
`:quit!`, `:qa!`, and `:qall!` also cancel when they end the session.
`:cq` requests a nonzero
exit, but GUI frontends may report Neovim's exit status differently, so prefer
the named command. A failed editor process also leaves the clipboard unchanged.
The editor may itself change the clipboard via your own configuration or plugins.

Set `auto_paste=true` to opt into macOS simulated Command-V after restoring
focus. This can replace a selection in the destination and some applications
may reject simulated input. macOS may require Accessibility and Automation
permissions for the host running the workflow and System Events. If paste fails,
the text remains on the clipboard. Clipboard-only mode is the default.

## History and migration

Each session creates a unique owner-only file under
`${TMPDIR:-/tmp}/vim-anywhere-$UID`. Inspect it with
`ls -lt "${TMPDIR:-/tmp}/vim-anywhere-$UID"`; remove unwanted files manually.
Temporary directories may be cleared by the OS. Older versions used
`${TMPDIR:-/tmp}/vim-anywhere`; those files are not moved or deleted. The
installer preserves your old `~/.vim-anywhere` in a backup directory and does
not import its MacVim `.path`; select `editor=mvim` if desired. Existing
`~/.config/vim-anywhere/config` is retained.

## Troubleshooting and manual checks

Run `~/.vim-anywhere/bin/run` from a terminal to see errors. If a shortcut does
nothing, enable the service, assign a nonconflicting shortcut, and grant any
requested Accessibility/Automation permissions in Privacy & Security. Check
that the editor and `nvim` are executable in the paths above. GUI-launched
processes may not inherit interactive shell environment variables.

After installing, verify the shortcut from another app, save text with `:wq`,
confirm clipboard and restored focus; repeat with an empty file, cancellation,
a failed launch, and with another Neovide window already open. If enabling
paste, test with an unselected text field and then a selection. Also verify
`:VimAnywhereCancel` and `:cq` with your installed Neovide version. These GUI
checks require a real desktop session.

See [FAQ](FAQ.md). Licensed under MIT.
