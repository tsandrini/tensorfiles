# --- profiles/home-git.nix
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
  cfg = config.home-manager.users.${user};
in {

  home-manager.users.${user} = {
    programs.git = {
      enable = _ true;
      delta = {
        enable = _ true;
        options = {
          navigate = _ true;
          syntax-theme = _ "Nord";
        };
      };
      userName = _ "${user}";
      userEmail = _ "tomas.sandrini@seznam.cz"; # TODO
      extraConfig = { github.user = _ "${user}"; };
    };

    # TODO modularize shell
    programs.zsh.shellAliases = lib.mkIf cfg.programs.zsh.enable {
      b = _ "git branch";
      bl = _ "git branch";
      bd = _ "git branch -d";
      bdf = _ "git branch -D";
      f = _ "git fetch";
      fo = _ "git fetch origin";
      c = _ "git commit";
      ca = _ "git commit -a";
      ch = _ "git checkout";
      chb = _ "git checkout -b";
      chr = _ "git checkout --";
      chra = _ "git checkout -- .";
      cl = _ "git clone";
      ph = _ "git push";
      phu = _ "git push --set-upstream";
      phuo = _ "git push --set-upstream origin";
      phuof = _ "git push --set-upstream --force origin";
      phuf = _ "git push --set-upstream --force";
      phf = _ "git push --force";
      pl = _ "git pull";
      plf = _ "git pull --force";
      plo = _ "git pull origin";
      plof = _ "git pull origin --force";
      a = _ "git add";
      aa = _ "git add *";
      r = _ "git reset HEAD";
      ra = _ "git reset HEAD *";
      s = _ "git status";
      sh = _ "git stash";
      sha = _ "git stash apply";
      rmc = _ "git rm --cached";
      m = _ "git merge";
      mf = _ "git merge --force";
      i = _ "git init";
      d = _ "git diff";
      l = _ "git log";
      lg1 = _
        "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
      lg2 = _
        "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      lg3 = _
        "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
    };
  };
}
