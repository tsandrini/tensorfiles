# platforms: x86_64-linux,aarch64-linux
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
        packages = with pkgs; [nil];

        languages.nix.enable = true;
        pre-commit.hooks = {
          # nix
          alejandra.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          # shell
          shellcheck.enable = true;
          shfmt.enable = true;
        };

        pre-commit.settings = {
          deadnix.exclude = ["etc"];
          alejandra.exclude = ["etc"];
          statix.ignore = ["etc"];
        };
      }
    ];
  }
