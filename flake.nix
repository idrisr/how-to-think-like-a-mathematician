{
  description = "template for math proofs";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    hippoid-tex.url = "github:idrisr/hippoid-tex";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs@{ nixpkgs, flake-utils, hippoid-tex, ... }:
    let
      system = flake-utils.lib.system.x86_64-linux;
      hooks = {
        nixfmt.enable = true;
        deadnix.enable = true;
        beautysh.enable = true;
        lacheck.enable = true;
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ hippoid-tex.overlays.hippoid-tex ];
      };
      cleaner = pkgs.writeShellApplication {
        runtimeInputs = [ tex ];
        name = "clean";
        text = ''
          latexmk -C -auxdir=aux -outdir=pdf
          latexmk -C -auxdir=. -outdir=.
        '';
      };
      makepdf = pkgs.writeShellApplication {
        runtimeInputs = [ tex ];
        name = "makepdf";
        text = ''
          mkdir -p aux pdf
          latexmk -interaction=nonstopmode -lualatex -auxdir=aux -outdir=pdf ./*tex
        '';
      };
      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-full;
        hippoid-tex = { pkgs = [ pkgs.hippoid-tex ]; };
      };
    in {
      checks.${system} = {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          inherit hooks;
        };
      };

      packages.${system}.default = tex;
      devShells.${system} = let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [{
            pre-commit.hooks = hooks;
            packages = [ tex pkgs.codespell pkgs.python312Packages.pygments ];
          }];
        };
      };

      apps.${system} = {
        clean = {
          type = "app";
          program = "${cleaner}/bin/clean";
        };
        makepdf = {
          type = "app";
          program = "${makepdf}/bin/makepdf";
        };
      };
    };
}
