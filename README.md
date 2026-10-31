# nvim-anywhere

Invoke a GUI Vim editor from another application, edit a private temporary file,
and return its contents to the clipboard. Focus returns to the original macOS
application; paste manually. Linux supports Wayland with Neovide and wl-clipboard.

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
for version requirements. On Linux install Neovide, a compatible Neovim, and
`wl-clipboard` (`wl-copy`). A Wayland session is required; X11 and i3 are not
supported.

Clone [pixelcmnd/nvim-anywhere](https://github.com/pixelcmnd/nvim-anywhere),
enter its checkout, and run the installer:

```bash
git clone https://github.com/pixelcmnd/nvim-anywhere.git
cd nvim-anywhere
./install
```

The installer
copies the current checkout into `~/.nvim-anywhere`, including local changes,
and preserves an existing installation and workflow in named backup directories.
It never downloads the original upstream repository. `~/.nvim-anywhere/update`
fast-forwards the installed checkout from the local source checkout used for
installation; the source checkout must remain available. Local changes in the
installation must be resolved first. `~/.nvim-anywhere/uninstall` removes the
shortcut workflow and moves the installation to a named backup; configuration,
backups and history remain.

### Shortcuts

On macOS enable NvimAnywhere in System Settings > Keyboard > Keyboard Shortcuts
> Services (or Quick Actions), then assign **Control+Option+Command+I**. The
installer preserves existing service shortcuts; choose another combination if
this one is already in use.

On Linux configure **Control+Alt+Super+I** yourself. For GNOME or KDE Plasma,
create a custom command shortcut in Keyboard Shortcuts settings. Use the absolute
path `~/.nvim-anywhere/bin/run`, replacing `~` with your home directory. For a
Nix installation use the absolute path to `nvim-anywhere` in your profile.
The installer does not change desktop or compositor settings.

Examples for a checkout installation (replace `~` with your absolute home path
if your compositor does not expand it):

```text
# Sway (~/.config/sway/config)
bindsym Control+Mod1+Mod4+i exec ~/.nvim-anywhere/bin/run

# Hyprland (~/.config/hypr/hyprland.conf)
bind = CTRL ALT SUPER, I, exec, ~/.nvim-anywhere/bin/run

# niri (~/.config/niri/config.kdl), inside binds { ... }
Ctrl+Alt+Super+I { spawn "~/.nvim-anywhere/bin/run"; }
```

Use a different binding if the suggested one is already in use. The compositor
controls focus when Neovide closes; explicit focus restoration is not guaranteed
on Linux. Automatic paste is available only on macOS.

### Nix on Linux and macOS

This repository provides flake packages for `x86_64-linux`, `aarch64-linux`,
`x86_64-darwin`, and `aarch64-darwin`. Add it as an input to your NixOS,
nix-darwin, or Home Manager flake, then add the package to
`environment.systemPackages` or `home.packages`, respectively:

```nix
# flake input
inputs.nvim-anywhere.url = "github:pixelcmnd/nvim-anywhere";
inputs.nvim-anywhere.inputs.nixpkgs.follows = "nixpkgs";

# In a module that receives inputs and pkgs:
inputs.nvim-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Use this expression as an item in the relevant package list. Alternatively,
`nix profile install github:pixelcmnd/nvim-anywhere` installs it to your profile.
The package supplies Neovide and a fallback Neovim, and adds wl-clipboard on
Linux. It prefers `nvim` from your PATH and common Nix profiles over the bundled
fallback, so a Nixvim-managed executable can provide its plugin runtime. Use
`follows` as above to pin nixpkgs through your consuming flake's lock file.
This repository does not commit its own lock file. For a non-NixOS system,
Neovide may need a graphics wrapper such as nixGL.

On macOS, Home Manager can install both the package and its Quick Action.
Import the module in your Home Manager configuration and enable it:

```nix
{
  imports = [ inputs.nvim-anywhere.homeManagerModules.default ];
  programs.nvim-anywhere = {
    enable = true;
    # Optional: this is the default; set to false to leave the shortcut unchanged.
    shortcut = "Ctrl+Option+Command+I";
  };
}
```

Ensure `inputs` is passed to Home Manager (for example via `extraSpecialArgs`).
The module manages `~/Library/Services/NvimAnywhere.workflow` as a Home Manager
link. If an unmanaged workflow already exists there, move it aside before
activation. By default, Home Manager configures Control+Option+Command+I.
Use a string such as `"Ctrl+Option+Command+I"` to choose a shortcut, or set
`shortcut = false;` to leave the existing macOS shortcut unchanged. Modifiers
are case-insensitive: `Ctrl`/`Control`, `Option`/`Opt`/`Alt`, `Cmd`/`Command`,
and `Shift` are accepted, followed by one letter or digit. macOS may require
logging out and back in before a changed shortcut is recognized. Choose a
nonconflicting shortcut; the module does not detect conflicts. The module
currently supports macOS only.

Without Home Manager, the macOS package provides
`share/nvim-anywhere/NvimAnywhere.workflow` to copy into `~/Library/Services`
from your Nix profile. The Nix workflow searches common Nix profiles for
`nvim-anywhere`, so make the package available in one of those profiles.

## Editor and behavior

Neovide is the default on macOS and Linux. Neovide launches your
normal Neovim configuration, including plugins and keymaps. No minimal Neovim
configuration is imposed. Neovide's `--no-fork` makes the process blocking and
an existing Neovide instance is not reused. A Neovide configuration specifying
`server` is incompatible with this session: use a local configuration without
that setting. `NEOVIDE_SERVER` is cleared for the session.

For persistent settings, create `~/.config/nvim-anywhere/config` (or
`$XDG_CONFIG_HOME/nvim-anywhere/config`) with simple, unquoted lines:

```text
editor=neovide
auto_paste=false
```

`editor` accepts `neovide`, an absolute executable path, or `mvim`/`gvim` on macOS.
On Linux a custom editor must be a Wayland client and must block until it exits.
An explicit `NVIM_ANYWHERE_EDITOR` environment variable overrides the file;
the legacy `VIM_ANYWHERE_EDITOR` is used if the new variable is unset. The file
overrides the platform default. If the new config file does not exist, the old
`~/.config/vim-anywhere/config` (or corresponding XDG path) is used. A custom executable receives only the
file path and must stay in the foreground and return a nonzero status on failure.
Paths ending in the supported editor names receive their editor-specific options.
The scripts search the inherited `PATH`, `~/.nix-profile/bin`,
`/etc/profiles/per-user/$USER/bin`, `/run/current-system/sw/bin`, and common
Homebrew locations without reading shell startup files. For an editor in another
location, specify an absolute path. Neovide also needs `nvim` on that search
path; for a custom Nix profile, expose Neovim through one of those directories
or the environment inherited by the service. `NEOVIM_BIN` takes precedence over
PATH when set, but GUI-launched services may not inherit it. For the macOS Quick
Action, install your configured `nvim` in a common Nix profile so the service
can find it. Prefer stable profile paths over individual `/nix/store` paths,
which change between generations. Legacy mvim and gvim on macOS retain support for
`~/.gvimrc.min` or `~/.vimrc.min`; Neovide does not use them.

Save and exit with `:wq`. A normal `:q` also completes successfully, including
an empty file. To cancel reliably in Neovide, MacVim or gVim, use
`:NvimAnywhereCancel` or exit with `:q!`; the clipboard is left unchanged.
`:quit!`, `:qa!`, and `:qall!` also cancel when they end the session.
`:cq` requests a nonzero exit, but GUI frontends may report Neovim's exit status differently, so prefer
the named command. A failed editor process also leaves the clipboard unchanged.
The editor may itself change the clipboard via your own configuration or plugins.

Set `auto_paste=true` to opt into macOS simulated Command-V after restoring
focus. This can replace a selection in the destination and some applications
may reject simulated input. macOS may require Accessibility and Automation
permissions for the host running the workflow and System Events. If paste fails,
the text remains on the clipboard. Clipboard-only mode is the default.

## History and migration

Each session creates a unique owner-only file under
`${TMPDIR:-/tmp}/nvim-anywhere-$UID`. Inspect it with
`ls -lt "${TMPDIR:-/tmp}/nvim-anywhere-$UID"`; remove unwanted files manually.
Temporary directories may be cleared by the OS.

Older versions used `${TMPDIR:-/tmp}/vim-anywhere` or
`${TMPDIR:-/tmp}/vim-anywhere-$UID` for history. Those files and the old
`~/.vim-anywhere` installation remain untouched. The old config is read as a
fallback; move it to `~/.config/nvim-anywhere/config` when convenient. The old
`:VimAnywhereCancel` command remains an alias. On macOS, disable or remove the
old VimAnywhere service shortcut before assigning it to NvimAnywhere. On Linux,
remove the old GNOME shortcut and assign the new shortcut in your desktop or
compositor. Existing gVim/xclip setups must migrate to Neovide and wl-clipboard.
The old MacVim `.path` is not imported; use `editor=mvim` if desired.

## Troubleshooting and manual checks

Run `~/.nvim-anywhere/bin/run` from a terminal to see errors. If a shortcut does
nothing, enable the service, assign a nonconflicting shortcut, and grant any
requested Accessibility/Automation permissions in Privacy & Security. Check
that the editor and `nvim` are executable in the paths above. GUI-launched
processes may not inherit interactive shell environment variables.

After installing, verify the shortcut from another app, save text with `:wq`,
confirm clipboard and restored focus; repeat with an empty file, cancellation,
a failed launch, and with another Neovide window already open. If enabling
paste, test with an unselected text field and then a selection. Also verify
`:NvimAnywhereCancel` and `:cq` with your installed Neovide version. These GUI
checks require a real desktop session.

See [FAQ](FAQ.md). Licensed under MIT.

For each Linux desktop or compositor, manually verify the shortcut, a saved and
an empty file, cancellation, clipboard contents, focus after closing Neovide,
and a second session while Neovide is already open. Check clipboard access and
focus in GNOME, Plasma, Sway, niri, and Hyprland; these require real sessions.
