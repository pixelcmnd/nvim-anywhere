<h2 align="center">nvim-anywhere</h2>

Edit text from any application using Neovide and your existing Neovim configuration.
When you finish editing, the text is copied to your clipboard so you can paste it back into the original application.

Supports macOS and Linux (Wayland). On macOS, it can also return focus to the original application and paste the text automatically.

## Installation

### Nix

Add nvim-anywhere to your flake inputs:

```nix
inputs.nvim-anywhere = {
  url = "github:pixelcmnd/nvim-anywhere";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add the package to home.packages or environment.systemPackages:

```nix
inputs.nvim-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.default;
```

The package includes Neovide, a fallback Neovim, and wl-clipboard on Linux. It uses your existing Neovim installation when one is available in PATH or a common Nix profile.

### macOS Home Manager module

The Home Manager module installs the package and configures a Quick Action:

```nix
{
  imports = [ inputs.nvim-anywhere.homeManagerModules.default ];

  programs.nvim-anywhere = {
    enable = true;
    # Default shortcut; set to false to leave the existing shortcut unchanged.
    shortcut = "Ctrl+Option+Command+I";
  };
}
```

Pass inputs to Home Manager through extraSpecialArgs.

The shortcut is configured automatically. Set shortcut = false; to keep your existing shortcut unchanged.

If you already have a manually installed ~/Library/Services/NvimAnywhere.workflow, move it aside before activating the module.

The flake supports `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`.

You can also install the package directly:

```bash
nix profile install github:pixelcmnd/nvim-anywhere
```

### From source

Install [Neovide](https://neovide.dev/installation.html) and Neovim first.
On Linux, you'll also need `wl-clipboard` and a Wayland session.

```bash
git clone https://github.com/pixelcmnd/nvim-anywhere.git
cd nvim-anywhere
./install
```

The installer copies the repository to ~/.nvim-anywhere and backs up any existing installation.

Keep the cloned repository if you want to update later:

```bash
~/.nvim-anywhere/update
```

To uninstall:

```bash
~/.nvim-anywhere/uninstall
```

## Keyboard shortcuts

### macOS

Open System Settings → Keyboard → Keyboard Shortcuts → Services, enable NvimAnywhere, and assign a shortcut, such as Control+Option+Command+I.

The Home Manager module configures this shortcut automatically.

If you installed the Nix package without the module, first copy share/nvim-anywhere/NvimAnywhere.workflow from the package to ~/Library/Services.

### Linux

Add a keyboard shortcut in your desktop environment or compositor that runs:

~/.nvim-anywhere/bin/run

For Nix installations, use nvim-anywhere from your Nix profile instead. Some desktop environments require the full executable path.

## Usage

1. Press your configured shortcut in any application.
2. Edit your text in Neovide.
3. Save and close with :wq.
4. Paste the text back into the original application.

On macOS, you can enable automatic pasting to skip the last step.

To cancel without modifying the clipboard, use :NvimAnywhereCancel or :q!.

Temporary files are kept in ${TMPDIR:-/tmp}/nvim-anywhere-$UID, allowing you to recover text from previous sessions.

## Configuration

Create `~/.config/nvim-anywhere/config` or `$XDG_CONFIG_HOME/nvim-anywhere/config` if you use a custom XDG configuration directory.

```text
editor=neovide
auto_paste=false
```

### Automatic pasting

Set auto_paste=true to automatically paste the edited text on macOS.
This may require Accessibility and Automation permissions. Be aware that automatic pasting can replace selected text in the original application.

### Editor

The default editor is Neovide. You can also specify an absolute path to another executable, or use mvim or gvim on macOS.
Custom editors must remain open until editing is complete. On Linux, they must also support Wayland.
The NVIM_ANYWHERE_EDITOR environment variable overrides the configured editor.

## Neovim configuration

Neovide uses your regular Neovim configuration. No separate configuration is required.
If Neovide cannot find your Neovim executable, make sure nvim is available in PATH or a common Nix profile. Alternatively, set NEOVIM_BIN to its executable path.
Neovide configurations that set server are not supported.

## License

[MIT](LICENSE)
