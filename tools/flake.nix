{
  description = "Global CLI tools installed to nix profile";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    pgit.url = "github:ErikOlson/pgit";
  };

  outputs = { nixpkgs, pgit, ... }:
    let
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.buildEnv {
            name = "global-tools";
            paths = [
              # Git multiplexer for process & product separation
              pgit.packages.${system}.default

              # GitHub CLI
              pkgs.github-cli

              # Fast recursive search
              pkgs.ripgrep

              # Helix editor (binary is `hx`)
              pkgs.helix
            ];
          };
        });
    };
}
