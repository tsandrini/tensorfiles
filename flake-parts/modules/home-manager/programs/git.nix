# --- flake-parts/modules/home-manager/programs/git.nix
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
{ localFlake }:
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.git;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.git = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.git = {
        enable = _ true;
        delta = {
          enable = _ true;
          options = {
            navigate = _ true;
            syntax-theme = _ "Nord";
          };
        };
        userName = mkIf (config.home.sessionVariables.DEFAULT_USERNAME != null) (
          _ config.home.sessionVariables.DEFAULT_USERNAME
        );
        userEmail = mkIf (config.home.sessionVariables.DEFAULT_MAIL != null) (
          _ config.home.sessionVariables.DEFAULT_MAIL
        );
        extraConfig = {
          github.user = mkIf (config.home.sessionVariables.DEFAULT_USERNAME != null) (
            _ config.home.sessionVariables.DEFAULT_USERNAME
          );
        };
        aliases = {
          b = _ "branch";
          bb = _ "!for k in `git branch -a | grep -v \"HEAD -> \" | sed s/^..//`;do echo -e `git log -1 --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset\" \"$k\" --`\\\\t\"$k\";done | sort";
          bl = _ "branch";
          bd = _ "branch -d";
          bdf = _ "branch -D";
          f = _ "fetch";
          fo = _ "fetch origin";
          c = _ "commit";
          ca = _ "commit -a";
          ch = _ "checkout";
          chb = _ "checkout -b";
          chr = _ "checkout --";
          chra = _ "checkout -- .";
          cl = _ "clone";
          ph = _ "push";
          phu = _ "push --set-upstream";
          phuo = _ "push --set-upstream origin";
          phuof = _ "push --set-upstream --force origin";
          phuf = _ "push --set-upstream --force";
          phf = _ "push --force";
          pl = _ "pull";
          plf = _ "pull --force";
          plo = _ "pull origin";
          plof = _ "pull origin --force";
          a = _ "add";
          aa = _ "add *";
          r = _ "reset HEAD";
          ra = _ "reset HEAD *";
          s = _ "status";
          sh = _ "stash";
          sha = _ "stash apply";
          rmc = _ "rm --cached";
          m = _ "merge";
          mf = _ "merge --force";
          i = _ "init";
          d = _ "diff";
          l = _ "log";
          commit-stats = _ "!git log --pretty=format:'%s' | cut -d \" \" -f 1 | sort | uniq -c | sort -nr";
          ext-stats = _ "!git ls-files | xargs wc -l | awk -F ' +|\\\\.|/' '{ sumlines[$NF] += $2 } END { for (ext in sumlines) print ext, sumlines[ext] }' | sort -k2nr";
          authors = _ "!git log --format='%aN <%aE>' | awk '{arr[$0]++} END{for (i in arr){print arr[i], i;}}' | sort -rn | cut -d\\  -f2-";
          authors-by-loc = _ "!git ls-files | xargs -n1 git blame --line-porcelain | sed -n 's/^author //p' | sort -f | uniq -ic | sort -nr";
          authors-by-commits = _ "shortlog -s -n --all --no-merges";
          lg1 = _ "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
          lg2 = _ "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
          lg3 = _ "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
