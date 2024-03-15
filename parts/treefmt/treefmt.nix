# --- parts/treefmt/treefmt.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{ pkgs, projectPath, ... }:
{
  package = pkgs.treefmt;
  flakeCheck = true;
  flakeFormatter = true;
  projectRootFile = projectPath + "/flake.nix";

  settings.formatter =
    let
      excludes = [
        "etc/**"
        "*.png"
        "*.woff2"
      ];
    in
    {
      deadnix.excludes = excludes;
      statix.excludes = excludes;
      prettier.excludes = excludes;
      nixfmt-rfc-style.excludes = excludes;
      # TODO, for some reason doesn't work
      # typos = {
      #   command = pkgs.runtimeShell;
      #   options = [
      #     "-eucx"
      #     ''
      #       ${pkgs.typos}/bin/typos --diff --format long --write-changes "$@"
      #     ''
      #     "--" # this argument is ignored by bash
      #   ];
      #   includes = ["*"];
      # };
    };

  programs = {
    deadnix.enable = true;
    statix.enable = true;
    prettier.enable = true;
    nixfmt-rfc-style.enable = true;
    # NOTE Choose a different formatter if you'd like to
    # nixfmt.enable = true;
    # alejandra.enable = true;
  };
}
