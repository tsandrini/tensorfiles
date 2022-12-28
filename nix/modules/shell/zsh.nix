# --- modules/shell/zsh.nix
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

{ config, options, pkgs, lib, ... }:

{
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    promptInit = "";
    shellInit = ''
    touch ~/.zshrc
    '';
    loginShellInit = ''
    macchina -KSU -i $(ip a | awk '/state UP/ {print $2}' | sed 's/.$//')
    '';
    ohMyZsh = {
      enable = true;
      theme = "spaceship";
      customPkgs = with pkgs; [
        spaceship-prompt
        nix-zsh-completions
      ];
      plugins = [
        "git"
        "git-flow"
        "colorize"
        "colored-man-pages"
        "nix"
      ];
    };

    shellAliases = {
      ls = "exa";
      ll = "exa -F --icons --group-directories-first -la --git --header --created --modified";
      tree = "exa -F --icons --group-directories-first -la --git --header --created --modified -T";
      cat = "bat -p --wrap=never --paging=never";
      less = "bat --paging=always";
      find = "fd";
      fd = "fd";
      grep = "rg";
      fetch = "macchina -KSU -i $(ip a | awk '/state UP/ {print $2}' | sed 's/.$//')";
      vim = "nvim";
    };
  };

  environment.systemPackages = with pkgs; [
    bat
    exa
    fd
    fzf
    jq
    ripgrep
    tldr
    macchina
  ];
}
