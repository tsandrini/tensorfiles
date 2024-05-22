# --- parts/shells/devenv.nix
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
  treefmt,
  rc2nix,
  devenv-root,
  ...
}:
{
  # DEVENV:  Fast, Declarative, Reproducible, and Composable Developer
  # Environments using Nix developed by Cachix. For more information refer to
  #
  # - https://devenv.sh/
  # - https://github.com/cachix/devenv

  # --------------------------
  # --- ENV & SHELL & PKGS ---
  # --------------------------
  packages = with pkgs; [
    # -- NIX UTILS --
    nil # Yet another language server for Nix
    statix # Lints and suggestions for the nix programming language
    deadnix # Find and remove unused code in .nix source files
    nix-output-monitor # Processes output of Nix commands to show helpful and pretty information
    nixfmt-rfc-style # An opinionated formatter for Nix
    # NOTE Choose a different formatter if you'd like to
    # nixfmt # An opinionated formatter for Nix
    # alejandra # The Uncompromising Nix Code Formatter

    # -- GIT RELATED UTILS --
    commitizen # Tool to create committing rules for projects, auto bump versions, and generate changelogs
    cz-cli # The commitizen command line utility
    fh # The official FlakeHub CLI
    gh # GitHub CLI tool
    gh-dash # Github Cli extension to display a dashboard with pull requests and issues

    # -- BASE LANG UTILS --
    markdownlint-cli # Command line interface for MarkdownLint
    nodePackages.prettier # Prettier is an opinionated code formatter
    typos # Source code spell checker
    treefmt # one CLI to format the code tree

    # -- (YOUR) EXTRA PKGS --
    nh # Yet another nix cli helper
    disko # Declarative disk partitioning and formatting using nix
    rc2nix # KDE: Convert rc files to nix expressions
    cachix # Command-line client for Nix binary cache hosting https://cachix.org
  ];

  enterShell = ''
    # Welcome splash text
    echo ""; echo -e "\e[1;37;42mWelcome to the tensorfiles devshell!\e[0m"; echo ""
  '';

  # ---------------
  # --- SCRIPTS ---
  # ---------------
  scripts = {
    "rename-project".exec = ''
      find $1 \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/tensorfiles/$2/g"
    '';
  };

  # -----------------
  # --- LANGUAGES ---
  # -----------------
  languages.nix.enable = true;

  # ----------------------------
  # --- PROCESSES & SERVICES ---
  # ----------------------------

  # ------------------
  # --- CONTAINERS ---
  # ------------------
  devcontainer.enable = true;

  # ----------------------
  # --- BINARY CACHING ---
  # ----------------------

  cachix.pull = [ "pre-commit-hooks" ];
  cachix.push = "tsandrini";

  # ------------------------
  # --- PRE-COMMIT HOOKS ---
  # ------------------------
  # NOTE All available hooks options are listed at
  # https://devenv.sh/reference/options/#pre-commithooks
  pre-commit = {
    hooks = {
      treefmt.enable = true;
      treefmt.package = treefmt;

      nil.enable = true; # Nix Language server, an incremental analysis assistant for writing in Nix.
      markdownlint.enable = true; # Markdown lint tool
      typos.enable = true; # Source code spell checker

      actionlint.enable = true; # GitHub workflows linting
      commitizen.enable = true; # Commitizen is release management tool designed for teams.
      editorconfig-checker.enable = true; # A tool to verify that your files are in harmony with your .editorconfig
    };
    excludes = [
      "etc"
      "secrets"
      ".*png"
      ".*woff2"
      "disko.nix"
    ];
  };

  # --------------
  # --- FLAKES ---
  # --------------
  devenv.flakesIntegration = true;

  # This is currently needed for devenv to properly run in pure hermetic
  # mode while still being able to run processes & services and modify
  # (some parts) of the active shell.
  devenv.root =
    let
      devenvRootFileContent = builtins.readFile devenv-root.outPath;
    in
    pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

  # ---------------------
  # --- MISCELLANEOUS ---
  # ---------------------
  difftastic.enable = true;
}
