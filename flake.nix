{
  description = "Hyprland rice dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nodejs_22
              python3
              go
              rustc
              cargo
              gcc
              gnumake
              cmake
              pkg-config
              git
              curl
              wget
              jq
              ripgrep
              fd
              eza
              bat
              fzf
              lazygit
              neovim
              tmux
              sqlite
              postgresql_17
              mariadb
            ];

            shellHook = ''
              echo "dots dev shell active"
              echo "  node $(node --version 2>/dev/null || echo 'not found')"
              echo "  python $(python3 --version 2>/dev/null || echo 'not found')"
              echo "  go $(go version 2>/dev/null | awk '{print $3}' || echo 'not found')"
              echo "  rust $(rustc --version 2>/dev/null || echo 'not found')"
            '';
          };
        }
      );
    };
}
