# --- treefmt.nix
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
{
  pkgs,
  projectRoot,
  ...
}: {
  package = pkgs.treefmt;
  flakeCheck = true;
  flakeFormatter = true;
  projectRootFile = projectRoot + "/flake.nix";

  settings.formatter = {
    alejandra.excludes = ["etc/**/*" "*.png" "*.woff2"];
    deadnix.excludes = ["etc/**/*" "*.png" "*.woff2"];
    statix.excludes = ["etc/**/*" "*.png" "*.woff2"];
    prettier.excludes = ["etc/**/*" "*.png" "*.woff2"];
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
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    prettier.enable = true;
  };
}
