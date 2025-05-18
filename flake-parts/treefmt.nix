# --- flake-parts/treefmt.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
{ inputs, ... }:
{
  imports = with inputs; [ treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
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
        projectRootFile = "flake.nix";

        settings = {
          global.excludes = [
            "etc/**/*"
            "*.age"
            "*.png"
            "*.woff2"
            "flake-parts/pkgs/docs/**/*"
          ];
          shellcheck.includes = [
            "*.sh"
            ".envrc"
          ];
          prettier.editorconfig = true;
        };

        programs = {
          deadnix.enable = true; # Find and remove unused code in .nix source files
          statix.enable = true; # Lints and suggestions for the nix programming language
          nixfmt.enable = true; # An opinionated formatter for Nix

          prettier.enable = true; # Prettier is an opinionated code formatter
          jsonfmt.enable = true; # Formatter for JSON files
          # yamlfmt.enable = true; # An extensible command line tool or library to format yaml files.
          # mdformat.enable = true; # CommonMark compliant Markdown formatter

          shellcheck.enable = true; # Shell script analysis tool
          shfmt.enable = true; # Shell parser and formatter

          # actionlint.enable = true; # Static checker for GitHub Actions workflow files
          # mdsh.enable = true; # Markdown shell pre-processor
        };
      };
    };
}
