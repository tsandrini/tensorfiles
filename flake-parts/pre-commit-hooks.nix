# --- flake-parts/pre-commit-hooks.nix
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
  imports = with inputs; [ pre-commit-hooks.flakeModule ];

  perSystem = _: {
    pre-commit.settings = {
      excludes = [
        "flake.lock" # NOTE: prettier thinks this is json >.< prettier baka!!!
        "p10k.zsh"
        "flake-parts/modules/home-manager/programs/file-managers/lf/icons"
        "etc/"
      ];

      hooks = {
        # --- Nix ---
        deadnix.enable = true; # Find and remove unused code in .nix source files
        nil.enable = true; # Nix Language server, an incremental analysis assistant for writing in Nix.
        nixfmt-rfc-style.enable = true; # An opinionated formatter for Nix
        statix.enable = true; # Lints and suggestions for the nix programming language

        # --- Shell ---
        shellcheck.enable = true; # Shell script analysis tool
        shfmt.enable = true; # Shell parser and formatter

        # --- Misc ---
        markdownlint.enable = true; # Markdown lint tool
        editorconfig-checker.enable = true; # .editorconfig file checker
        typos.enable = true; # Source code spell checker
        prettier.enable = true; # Prettier is an opinionated code formatter
        # jsonfmt.enable = true; # Formatter for JSON files

        # --- fs utils ---
        check-added-large-files.enable = true;
        check-executables-have-shebangs.enable = true;
        end-of-file-fixer.enable = true;
        mixed-line-endings.enable = true;
        trim-trailing-whitespace.enable = true;

        # --- VCS ---
        # actionlint.enable = true; # GitHub workflows linting
        commitizen.enable = true; # Commitizen is release management tool designed for teams.
        ripsecrets.enable = true; # A tool to prevent committing secret keys into your source code
      };
    };
  };
}
