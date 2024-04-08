{
  description = "template for math proofs";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/23.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.hippoid-tex.url = "github:idrisr/hippoid-tex";

  outputs = { nixpkgs, flake-utils, hippoid-tex, ... }:
    let
      system = flake-utils.lib.system.x86_64-linux;
      pkgs = import nixpkgs { inherit system; };
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
          latexmk -interaction=nonstopmode -lualatex -pdf -auxdir=aux -outdir=pdf ./*tex
        '';
      };
      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-full;
        hippoid-tex = {
          pkgs = [ hippoid-tex.packages.${system}.hippoid-tex ];
        };
      };
    in {
      packages.${system}.default = tex;
      devShells.${system} = {
        default = pkgs.mkShell { buildInputs = [ tex ]; };
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
