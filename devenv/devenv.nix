# --- shells/devenv.nix
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
  config,
  ...
}: {
  packages = with pkgs; [
    # -- greeting --
    cowsay
    fortune
    lolcat
    # -- nix --
    nil # LSP
    alejandra # formatting
    statix # static code analysis
    deadnix # find dead nix code
    nix-output-monitor # readable derivation outputs
    # -- misc --
    markdownlint-cli # markdown linting
    typos # spell checking
    # -- git, flakehub --
    commitizen
    cz-cli
    fh # flakehub cli

    config.treefmt.build.wrapper
  ];

  languages.nix.enable = true;
  difftastic.enable = true;
  devcontainer.enable = true; # if anyone needs it
  devenv.flakesIntegration = true;

  pre-commit = {
    excludes = ["etc" "secrets" ".*png" ".*woff2"];
    hooks = {
      treefmt.enable = true;
      # Everything below is stuff that I couldn't make work with treefmt
      nil.enable = true;
      commitizen.enable = true;
      markdownlint.enable = true;
      typos.enable = true;
      actionlint.enable = true;
    };
    settings = {
      treefmt.package = config.treefmt.build.wrapper;
    };
  };

  enterShell = ''
    echo ""
    echo "~~ Welcome to the tensorfiles devshell! ~~

    [Fortune of the Day] $(fortune)" | cowsay -W 120 -T "U " | lolcat -F 0.3 -p 10 -t
    echo ""
  '';
}
