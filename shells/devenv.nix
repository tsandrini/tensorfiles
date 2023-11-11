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
        packages = with pkgs; [
          cowsay
          fortune
          lolcat
          nil
          shellcheck
          shfmt
          markdownlint-cli
          typos
          commitizen
          cz-cli
        ];

        languages.nix.enable = true;
        difftastic.enable = true;
        devcontainer.enable = true; # if anyone needs it

        devenv = {
          flakesIntegration = true;
        };

        pre-commit = {
          excludes = ["etc"];
          hooks = {
            # nix
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
            # shell
            # shellcheck.enable = true;
            # shfmt.enable = true;
            # git
            commitizen.enable = true;
            # markdown
            markdownlint.enable = true;
            # spell checking
            typos.enable = true;
            # github actions
            actionlint.enable = true;
          };
          # settings = {
          #   deadnix.exclude = ["etc"];
          #   alejandra.exclude = ["etc"];
          #   statix.ignore = ["etc"];
          # };
        };

        enterShell = ''
          echo ""
          echo "~~ Welcome to tensorfiles devshell! ~~

          [Fortune of the Day] $(fortune)" | cowsay -W 120 -T "U " | lolcat -F 0.3 -p 10 -t
          echo ""
        '';
      }
    ];
  }
