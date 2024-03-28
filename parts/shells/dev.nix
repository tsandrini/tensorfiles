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
  projectPath,
  ...
}:
{
  # Needed for devenv to run in pure mode
  devenv.root = builtins.toString projectPath;

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

    # -- LANGUAGE RELATED UTILS --
    markdownlint-cli # Command line interface for MarkdownLint
    nodePackages.prettier # Prettier is an opinionated code formatter
    typos # Source code spell checker
    treefmt # one CLI to format the code tree

    # -- NIXOS UTILS --
    nh # Yet another nix cli helper
    disko # Declarative disk partitioning and formatting using nix
    rc2nix # KDE: Convert rc files to nix expressions
    cachix # Command-line client for Nix binary cache hosting https://cachix.org
  ];

  languages.nix.enable = true;
  difftastic.enable = true;
  devcontainer.enable = true; # if anyone needs it
  devenv.flakesIntegration = true;

  cachix.pull = [ "pre-commit-hooks" ];
  cachix.push = "tsandrini";

  pre-commit = {
    hooks = {
      treefmt.enable = true;

      # Everything below is stuff that I couldn't make work with treefmt
      nil.enable = true;
      commitizen.enable = true;
      typos.enable = true;
      actionlint.enable = true;

      editorconfig-checker.enable = true;
    };
    settings = {
      treefmt.package = treefmt;
    };
    excludes = [
      "etc"
      "secrets"
      ".*png"
      ".*woff2"
      "disko.nix"
    ];
  };

  enterShell = ''
    # Greeting upon devshell activation
    echo ""; echo -e "\e[1;37;42mWelcome to the tensorfiles devshell!\e[0m"; echo ""
  '';
}
