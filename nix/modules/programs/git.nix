# --- modules/programs/git.nix
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
{ config, lib, pkgs, user ? "root", ... }:
with builtins;
with lib;
let
  cfg = config.tensorfiles.programs.git;
  _ = mkOverride 500;
in {
  # TODO add non-hm nixos only based configuration
  options.tensorfiles.programs.git = with types; {
    enable = mkEnableOption (mdDoc ''
      Enable zsh configuration module
    '');

    home = {
      enable = mkEnableOption (mdDoc ''
        Enable multi-user configuration via home-manager.

        The configuration is then done via the settings option with the toplevel
        attribute being the name of the user, for example:

        ```nix
        home.enable = true;
        home.settings."root" = {
          withAutocompletions = false;
        };
        home.settings."myUser" = {
          withAutocompletions = true;
        };
        ```
      '');

      settings = mkOption {
        type = attrsOf (submodule ({ name, ... }: {
          options = {

            userName = mkOption {
              type = nullOr str;
              default = null;
              description = mdDoc ''
                TODO
              '';
            };

            userEmail = mkOption {
              type = addCheck str (str:
                match "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}" str
                != null);
              default = "tomas.sandrini@seznam.cz";
              description = mdDoc ''
                TODO
              '';
            };
          };
        }));
        # Note: It's sufficient to just create the toplevel attribute and the
        # rest will be automatically populated with the default option values.
        default = { "${user}" = { }; };
        description = mdDoc ''
          The configuration is then done via the settings option with the toplevel
          attribute being the name of the user, for example:

          ```nix
          home.enable = true;
          home.settings."root" = {
            withAutocompletions = false;
          };
          home.settings."myUser" = {
            withAutocompletions = true;
          };
          ```
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      assertions = [{
        assertion = cfg.home.enable && (hasAttr "home-manager" config);
        message =
          "home configuration enabled, however, home-manager missing, please install and import the home-manager module";
      }];
    })
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let
          userCfg = cfg.home.settings."${_user}";
          userName =
            if userCfg.userName != null then userCfg.userName else "${_user}";
        in {
          programs.git = {
            enable = _ true;
            delta = {
              enable = _ true;
              options = {
                navigate = _ true;
                syntax-theme = _ "Nord";
              };
            };
            userName = _ userName;
            userEmail = _ userCfg.userEmail;
            extraConfig = { github.user = _ userName; };
            aliases = {
              b = _ "branch";
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
              lg1 = _
                "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
              lg2 = _
                "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
              lg3 = _
                "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
            };
          };

        });
    })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
