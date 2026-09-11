{
  description = "Global CLI tools installed to nix profile";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    pgit.url = "github:ErikOlson/pgit";
    ccg.url = "github:ErikOlson/ccg";
  };

  outputs = { nixpkgs, pgit, ccg, ... }:
    let
      # x86_64-darwin omitted: nixpkgs 26.11 dropped support for Intel Macs.
      # For those, use the `x86-darwin-last` git tag (nixpkgs pinned 2026-02-07).
      supportedSystems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
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

              # Claude Code Git — keep Claude files out of product repo.
              # TODO: probably superseded by pgit above, which generalizes the
              # same idea. ccg is also a PRIVATE repo, so nix's github: fetcher
              # 404s unauthenticated: it silently never updates, and a fresh
              # machine cannot bootstrap. Decide to drop it or make it public.
              ccg.packages.${system}.default

              # GitHub CLI
              pkgs.github-cli

              # Fast recursive search
              pkgs.ripgrep

              # Helix editor (binary is `hx`)
              pkgs.helix

              # Terminal agent multiplexer
              pkgs.herdr
            ];
          };
        });
    };
}
