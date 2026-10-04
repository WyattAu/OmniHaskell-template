{
  # OmniHaskell dev environment — nix owns GHC + tooling (the pin everyone
  # shares), cabal owns Haskell packages (dist-newstyle stays incremental).
  description = "OmniHaskell-template development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
      ghcPkgs = pkgs: pkgs.haskell.packages.ghc98;
    in
    {
      devShells = forAllSystems (pkgs:
        let hp = ghcPkgs pkgs;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cabal-install
              (hp.ghc.withPackages (_: [])) # GHC 9.8 — baseline (ADR-0002)
              hp.haskell-language-server
              hp.fourmolu
              hp.cabal-fmt
              hlint
              git
            ];

            shellHook = ''
              echo "OmniHaskell: $(ghc --version | cut -d' ' -f8) baseline / HLS ready"
            '';
          };
        });
    };
}
