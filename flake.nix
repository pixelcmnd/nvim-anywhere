{
  description = "Edit text anywhere with Neovide";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "nvim-anywhere";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/libexec/nvim-anywhere" "$out/bin"
            cp -R bin script "$out/libexec/nvim-anywhere/"
            makeWrapper "$out/libexec/nvim-anywhere/bin/run" "$out/bin/nvim-anywhere" \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.neovide pkgs.neovim pkgs.wl-clipboard pkgs.coreutils pkgs.gnugrep ]}
            runHook postInstall
          '';
          meta = {
            description = "Edit text anywhere using Neovide on Wayland";
            license = pkgs.lib.licenses.mit;
            platforms = pkgs.lib.platforms.linux;
            mainProgram = "nvim-anywhere";
          };
        };
      });
    };
}
