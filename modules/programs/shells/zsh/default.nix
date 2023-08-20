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
{ config, lib, pkgs, user ? "root", ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.programs.shells.zsh;
  _ = mkOverrideAtModuleLevel;
in {
  # TODO add non-hm nixos only based configuration
  options.tensorfiles.programs.shells.zsh = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the zsh shell.
      '');

      package = mkOption {
        type = package;
        default = pkgs.zsh;
        description = mdDoc ''
          The zsh package (derivation or path) that should be used for the
          internals of this module.
        '';
      };

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: {

          withAutocompletions = mkOption {
            type = bool;
            default = true;
            description = mdDoc ''
              Whether to enable autosuggestions/autocompletion related code
            '';
          };

          p10k = {
            enable = mkAlreadyEnabledOption (mdDoc ''
              Whether to enable the powerlevel10k theme (and plugins) related
              code.
            '');

            cfgSrc = mkOption {
              type = path;
              default = ./.;
              description = mdDoc ''
                Path (or ideally, path inside a derivation) for the p10k.zsh
                configuration file

                Note: This should point just to the target directory. If you
                want to change the default filename of the `p10k.zsh` file,
                modify the cfgFile option.
              '';
            };

            cfgFile = mkOption {
              type = str;
              default = "p10k.zsh";
              description = mdDoc ''
                Potential override of the p10k.zsh config filename.
              '';
            };
          };

          oh-my-zsh = {
            enable = mkAlreadyEnabledOption (mdDoc ''
              Whether to enable the oh-my-zsh framework related code
            '');

            plugins = mkOption {
              type = listOf str;
              default = [ "git" "git-flow" "colorize" "colored-man-pages" ];
              description = mdDoc ''
                oh-my-zsh plugins that are enabled by default
              '';
            };
          };

          shellAliases = {

            lsToExa = mkOption {
              type = bool;
              default = true;
              description = mdDoc ''
                Enable predefined shell aliases
              '';
            };

            catToBat = mkOption {
              type = bool;
              default = true;
              description = mdDoc ''
                Remap the cat related commands to its reworked edition bat.
              '';
            };

            findToFd = mkOption {
              type = bool;
              default = true;
              description = mdDoc ''
                Remap the find related commands to its reworked edition fd.
              '';
            };

            grepToRipgrep = mkOption {
              type = bool;
              default = true;
              description = mdDoc ''
                Remap the find related commands to its reworked edition fd.
              '';
            };
          };
        });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      assertions = with tensorfiles.asserts;
        [ (mkIf cfg.home.enable (assertHomeManagerLoaded config)) ];
    })
    # |----------------------------------------------------------------------| #
    ({ users.defaultUserShell = _ cfg.package; })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          home.packages = with pkgs;
            with userCfg.shellAliases;
            [ nitch ] ++ (optional lsToExa exa) ++ (optional catToBat bat)
            ++ (optional findToFd fd) ++ (optional grepToRipgrep ripgrep);

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
          };

          home.shellAliases = mkMerge [
            { fetch = _ "${pkgs.nitch}/bin/nitch"; }
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
        });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
