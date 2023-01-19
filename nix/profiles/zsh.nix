# --- profiles/zsh.nix
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

{ config, pkgs, lib, inputs, user, ... }:

let
  _ = lib.mkOverride 500;
in {
  users.defaultUserShell = _ pkgs.zsh;

  environment.variables = {
    EDITOR = _ "nvim";
    VISUAL = _ "nvim";
  };

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      bat
      exa
      fd
      fzf
      jq
      ripgrep
      tldr
      macchina
    ];

    programs.zsh = {
      enable = _ true;
      enableSyntaxHighlighting = _ true;
      enableAutosuggestions = _ true;
      # initExtra = '' # TODO probably not needed
      #   touch ~/.zshrc
      # '';
      # plugins = with pkgs; [
      #   spaceship-prompt
      #   nix-zsh-completions
      # ];
      plugins = [
        {
          name = "spaceship-prompt";
          src = pkgs.spaceship-prompt;
        }
        {
          name = "nix-zsh-completions";
          src = pkgs.nix-zsh-completions;
        }
      ];
      loginExtra = _ ''
        macchina -KSU -i $(ip a | awk '/state UP/ {print $2}' | sed 's/.$//')
      '';
      oh-my-zsh = {
        enable = _ true;
        theme = _ "spaceship";
        plugins = [
          "git"
          "git-flow"
          "colorize"
          "colored-man-pages"
          "nix"
        ];
      };
      shellAliases = {
        ls = _ "exa";
        ll = _ "exa -F --icons --group-directories-first -la --git --header --created --modified";
        tree = _ "exa -F --icons --group-directories-first -la --git --header --created --modified -T";
        cat = _ "bat -p --wrap=never --paging=never";
        less = _ "bat --paging=always";
        find = _ "fd";
        fd = _ "fd";
        grep = _ "rg";
        fetch = _ "macchina -KSU -i $(ip a | awk '/state UP/ {print $2}' | sed 's/.$//')";
        vim = _ "nvim";
      };
    };
  };
}
