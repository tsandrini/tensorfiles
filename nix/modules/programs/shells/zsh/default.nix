# --- modules/programs/shells/zsh/default.nix
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
{ config, lib, pkgs, user ? "", ... }:
with builtins;
with lib;
let
  cfg = config.tensorfiles.programs.shells.zsh;
  _ = mkOverride 500;
in {
  options.tensorfiles.programs.shells.zsh = with types; rec {
    enable = mkEnableOption (mdDoc ''
      Enable zsh configuration module
    '');

    home = {
      enable = mkEnableOption (mdDoc ''
        Enable zsh multi-user configuration via home-manager.
      '');

      settings = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {

            withAutocompletions = mkOption {
              type = bool;
              default = true;
              description = mdDoc ''
                TODO
              '';
            };

            p10k = {
              enable = mkEnableOption (mdDoc ''
                TODO
              '') // {
                default = true;
              };

              cfgSrc = mkOption {
                type = path;
                default = ./.;
                description = mdDoc ''
                  TODO
                '';
              };

              cfgFile = mkOption {
                type = str;
                default = "p10k.zsh";
                description = mdDoc ''
                  TODO
                '';
              };
            };

            oh-my-zsh = {
              enable = mkEnableOption (mdDoc ''
                TODO
              '') // {
                default = true;
              };

              plugins = mkOption {
                type = listOf str;
                default = [ "git" "git-flow" "colorize" "colored-man-pages" ];
                description = mdDoc ''
                  TODO
                '';
              };
            };

            shellAliases = {
              lsToExa = mkOption {
                type = bool;
                default = true;
                description = mdDoc ''
                  TODO
                '';
              };
              catToBat = mkOption {
                type = bool;
                default = true;
                description = mdDoc ''
                  TODO
                '';
              };
              findToFd = mkOption {
                type = bool;
                default = true;
                description = mdDoc ''
                  TODO
                '';
              };
              grepToRipgrep = mkOption {
                type = bool;
                default = true;
                description = mdDoc ''
                  TODO
                '';
              };
            };

          };
        }));
        default = {
          "${user}" = {
            # this should hopefully be enough? #TODO test
          };
        };
        description = mdDoc "Settings for my service";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      #
    })
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          programs.zsh = {
            enable = _ true;
            enableSyntaxHighlighting = _ true;
            enableAutosuggestions = _ userCfg.withAutocompletions;
            oh-my-zsh = mkIf userCfg.oh-my-zsh.enable {
              enable = _ true;
              plugins = userCfg.oh-my-zsh.plugins;
            };
            plugins = [
              (mkIf userCfg.withAutocompletions {
                name = "nix-zsh-completions";
                src = pkgs.nix-zsh-completions;
                file = "share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh";
              })
              (mkIf userCfg.p10k.enable {
                name = "zsh-powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
              })
              (mkIf userCfg.p10k.enable {
                name = "powerlevel10k-config";
                src = userCfg.p10k.cfgSrc;
                file = userCfg.p10k.cfgFile;
              })
            ];
            loginExtra = _ "${pkgs.nitch}/bin/nitch";
            shellAliases = mkMerge [
              (mkIf userCfg.shellAliases.lsToExa {
                ls = _ "${pkgs.exa}/bin/exa";
                ll = _
                  "${pkgs.exa}/bin/exa -F --icons --group-directories-first -la --git --header --created --modified";
                tree = _
                  "${pkgs.exa}/bin/exa -F --icons --group-directories-first -la --git --header --created --modified -T";
              })
              (mkIf userCfg.shellAliases.catToBat {
                cat = _ "${pkgs.bat}/bin/bat -p --wrap=never --paging=never";
                less = _ "${pkgs.bat}/bin/bat --paging=always";
              })
              (mkIf userCfg.shellAliases.findToFd {
                find = _ "${pkgs.fd}/bin/fd";
                fd = _ "${pkgs.fd}/bin/fd";
              })
              (mkIf userCfg.shellAliases.grepToRipgrep {
                grep = _ "${pkgs.ripgrep}/bin/rg";
              })
              { fetch = _ "${pkgs.nitch}/bin/nitch"; }
            ];
          };
        });
    })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
