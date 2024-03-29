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
  # treefmt is a formatting tool that saves you time: it provides
  # developers with a universal way to trigger all formatters needed for the
  # project in one place.
  # For more information refer to
  #
  # - https://numtide.github.io/treefmt/
  # - https://github.com/numtide/treefmt-nix

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
    deadnix.enable = true; # Find and remove unused code in .nix source files
    statix.enable = true; # Lints and suggestions for the nix programming language
    nixfmt-rfc-style.enable = true; # An opinionated formatter for Nix
    # NOTE Choose a different formatter if you'd like to
    # nixfmt.enable = true; # An opinionated formatter for Nix
    # alejandra.enable = true; # The Uncompromising Nix Code Formatter

    prettier.enable = true; # Prettier is an opinionated code formatter
    mdformat.enable = true; # CommonMark compliant Markdown formatter
    yamlfmt.enable = true; # An extensible command line tool or library to format yaml files.
    jsonfmt.enable = true; # Formatter for JSON files

    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
