{
  description = "Edit text anywhere with Neovide";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    homeManagerModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.programs.nvim-anywhere;
      modifierSymbols = {
        ctrl = "^";
        control = "^";
        opt = "~";
        option = "~";
        alt = "~";
        cmd = "@";
        command = "@";
        shift = "$";
      };
      isShortcut = value: let
        parts = lib.splitString "+" (lib.toLower value);
        modifiers = lib.init parts;
        key = lib.last parts;
        validModifiers = lib.all (modifier: builtins.hasAttr modifier modifierSymbols) modifiers;
        symbols = map (modifier: modifierSymbols.${modifier}) modifiers;
      in
        modifiers
        != []
        && validModifiers
        && builtins.length (lib.unique symbols) == builtins.length symbols
        && builtins.match "[a-z0-9]" key != null;
      keyEquivalent =
        if cfg.shortcut == false
        then ""
        else let
          parts = lib.splitString "+" (lib.toLower cfg.shortcut);
        in
          lib.concatMapStrings (modifier: modifierSymbols.${modifier}) (lib.init parts) + lib.last parts;
    in {
      options.programs.nvim-anywhere = {
        enable = lib.mkEnableOption "nvim-anywhere and its macOS Quick Action";
        shortcut = lib.mkOption {
          type = lib.types.either (lib.types.enum [false]) (lib.types.addCheck lib.types.str isShortcut);
          default = "Ctrl+Option+Command+I";
          example = "Ctrl+Option+Command+I";
          description = "Quick Action shortcut as modifiers and a letter or digit; false leaves the existing shortcut unchanged.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          description = "The nvim-anywhere package to install.";
        };
      };
      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isDarwin;
            message = "programs.nvim-anywhere currently manages a macOS Quick Action and requires Darwin.";
          }
        ];
        home.packages = [cfg.package];
        home.activation.nvimAnywhereShortcut = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.shortcut != false) (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            run /usr/bin/osascript -l JavaScript ${./script/set-shortcut.js} ${lib.escapeShellArg keyEquivalent}
          ''
        );
        home.file."Library/Services/NvimAnywhere.workflow" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          source = "${cfg.package}/share/nvim-anywhere/NvimAnywhere.workflow";
        };
      };
    };

    packages = forAllSystems (pkgs: {
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "nvim-anywhere";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = [pkgs.makeWrapper];
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/libexec/nvim-anywhere" "$out/bin"
          cp -R bin script "$out/libexec/nvim-anywhere/"
          makeWrapper "$out/libexec/nvim-anywhere/bin/run" "$out/bin/nvim-anywhere" \
            --prefix PATH : ${pkgs.lib.makeBinPath ([pkgs.neovide pkgs.neovim pkgs.coreutils pkgs.gnugrep] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.wl-clipboard])}
          ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            mkdir -p "$out/share/nvim-anywhere"
            cp -R NvimAnywhere.workflow "$out/share/nvim-anywhere/"
            substituteInPlace "$out/share/nvim-anywhere/NvimAnywhere.workflow/Contents/document.wflow" \
              --replace-fail '"$HOME/.nvim-anywhere/bin/run"' 'PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$(/usr/bin/id -un)/bin:/run/current-system/sw/bin:/usr/bin:/bin"; export PATH; exec nvim-anywhere'
          ''}
          runHook postInstall
        '';
        meta = {
          description = "Edit text anywhere using Neovide on macOS and Wayland";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
          mainProgram = "nvim-anywhere";
        };
      };
    });
  };
}
