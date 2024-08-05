# --- flake-parts/shells/dev.nix
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
  lib,
  mkShell,
  nil,
  statix,
  deadnix,
  nix-output-monitor,
  nixfmt-rfc-style,
  commitizen,
  cz-cli,
  # fh, # TODO error[E0425]: cannot find function `parse` in module `crate::ffi`
  gh,
  nh,
  nix-fast-build,
  disko,
  rc2nix,
  cachix,
  markdownlint-cli,
  writeShellScriptBin,
  treefmt-wrapper ? null,
  dev-process ? null,
  pre-commit ? null,
}:
let
  scripts = {
    rename-project = writeShellScriptBin "rename-project" ''
      find $1 \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/tensorfiles/$2/g"
    '';
  };

  env = {
    # MY_ENV_VAR = "Hello, World!";
    # MY_OTHER_ENV_VAR = "Goodbye, World!";
  };
in
mkShell {

  packages =
    (lib.attrValues scripts)
    ++ (lib.optional (treefmt-wrapper != null) treefmt-wrapper)
    ++ (lib.optional (dev-process != null) dev-process)
    ++ [
      # -- NIX UTILS --
      nil # Yet another language server for Nix
      statix # Lints and suggestions for the nix programming language
      deadnix # Find and remove unused code in .nix source files
      nix-output-monitor # Processes output of Nix commands to show helpful and pretty information
      nixfmt-rfc-style # An opinionated formatter for Nix

      # -- GIT RELATED UTILS --
      commitizen # Tool to create committing rules for projects, auto bump versions, and generate changelogs
      cz-cli # The commitizen command line utility
      # TODO error[E0425]: cannot find function `parse` in module `crate::ffi`
      # fh # The official FlakeHub CLI
      gh # GitHub CLI tool
      # gh-dash # Github Cli extension to display a dashboard with pull requests and issues

      # -- BASE LANG UTILS --
      markdownlint-cli # Command line interface for MarkdownLint
      # nodePackages.prettier # Prettier is an opinionated code formatter
      # typos # Source code spell checker

      # -- (YOUR) EXTRA PKGS --
      nh # Yet another nix cli helper
      disko # Declarative disk partitioning and formatting using nix
      rc2nix # KDE: Convert rc files to nix expressions
      cachix # Command-line client for Nix binary cache hosting https://cachix.org
      nix-fast-build # Combine the power of nix-eval-jobs with nix-output-monitor to speed-up your evaluation and building process
    ];

  shellHook = ''
    ${lib.concatLines (lib.mapAttrsToList (name: value: "export ${name}=${value}") env)}
    ${lib.optionalString (pre-commit != null) pre-commit.installationScript}

    # Welcome splash text
    echo ""; echo -e "\e[1;37;42mWelcome to the tensorfiles devshell!\e[0m"; echo ""
  '';
}
