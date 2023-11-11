# platforms: x86_64-linux,aarch64-linux,aarch64-darwin
{
  inputs,
  lib,
  system,
  ...
}:
with builtins;
with lib; let
  inherit (inputs) devenv;

  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
  devenv.lib.mkShell {
    inherit inputs pkgs;
    modules = [
      {
        packages = with pkgs; [nil shellcheck shfmt markdownlint-cli typos commitizen cz-cli];

        languages.nix.enable = true;
        pre-commit.hooks = {
          # nix
          alejandra.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          nil.enable = true;
          # shell
          shellcheck.enable = true;
          shfmt.enable = true;
          # git
          commitizen.enable = true;
          # markdown
          markdownlint.enable = true;
          # spell checking
          typos.enable = true;
        };

        pre-commit.settings = {
          deadnix.exclude = ["etc"];
          alejandra.exclude = ["etc"];
          statix.ignore = ["etc"];
        };
      }
    ];
  }
