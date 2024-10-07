# --- flake-parts/modules/programs/shells/fish.nix
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
{ localFlake }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    mkMerge
    optional
    mkBefore
    mkEnableOption
    mkOption
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.programs.shells.fish;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.shells.fish = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the fish shell.
    '';

    pywal = {
      enable = mkPywalEnableOption;
    };

    nixpkgsPlugins = mkOption {
      type = types.listOf types.str;
      default = [
        "done"
        "grc"
        "foreign-env"
        "colored-man-pages"
        "autopair"
        "sponge"
        "z"
        # "fzf-fish"
        # "forgit"
      ];
      description = ''
        List of fish plugins from nixpkgs to be installed.
      '';
    };

    withFzf = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable the fzf plugin
      '';
    };

    shellAliases = {
      lsToEza = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable predefined shell aliases
        '';
      };

      catToBat = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Remap the cat related commands to its reworked edition bat.
        '';
      };

      findToFd = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Remap the find related commands to its reworked edition fd.
        '';
      };

      grepToRipgrep = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Remap the find related commands to its reworked edition fd.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages =
        with pkgs;
        with cfg.shellAliases;
        [
          nitch
          grc
          any-nix-shell
        ]
        ++ (optional lsToEza eza)
        ++ (optional catToBat bat)
        ++ (optional findToFd fd)
        ++ (optional grepToRipgrep ripgrep);

      programs.fish = {
        enable = _ true;
        interactiveShellInit = mkBefore ''
          set fish_greeting

          if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          end
          if test -e ~/.nix-profile/etc/profile.d/nix.sh
            fenv source ~/.nix-profile/etc/profile.d/nix.sh
          end
          if test -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh
            fenv source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
          end

          ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

          ${getExe pkgs.microfetch}
        '';
        plugins =
          (optional cfg.withFzf {
            name = "fzf-fish";
            inherit (pkgs.fishPlugins.fzf-fish) src;
          })
          ++ (map (_plugin: {
            name = _plugin;
            inherit (pkgs.fishPlugins.${_plugin}) src;
          }) cfg.nixpkgsPlugins);
      };

      programs.starship = {
        enable = _ true;
        # NOTE enabled by default so probably unnecessary
        # enableBashIntegration = _ true;
        # enableFishIntegration = _ true;
      };

      home.shellAliases = mkMerge [
        {
          fetch = _ "${getExe pkgs.microfetch}";
          g = _ "${getExe config.programs.git.package}";
        }
        (mkIf cfg.shellAliases.lsToEza {
          ls = _ "${getExe pkgs.eza}";
          ll = _ "${getExe pkgs.eza} -F --hyperlink --icons --group-directories-first -la --git --header --created --modified";
          tree = _ "${getExe pkgs.eza} -F --hyperlink --icons --group-directories-first -la --git --header --created --modified -T";
        })
        (mkIf cfg.shellAliases.catToBat {
          cat = _ "${getExe pkgs.bat} -p --wrap=never --paging=never";
          less = _ "${getExe pkgs.bat} --paging=always";
        })
        (mkIf cfg.shellAliases.findToFd {
          find = _ "${getExe pkgs.fd}";
          fd = _ "${getExe pkgs.fd}";
        })
        (mkIf cfg.shellAliases.grepToRipgrep {
          grep = _ "${getExe pkgs.ripgrep}";
          list-todos = _ "${getExe pkgs.ripgrep} -g '!{.git,node_modules,result,build,dist,.idea,out,.DS_Store}' --no-follow 'TODO|FIXME' ";
        })
      ];
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withFzf {
      programs.fzf = {
        enable = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf ((isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable) {
      programs.fish.interactiveShellInit = mkBefore ''
        # Import colorscheme from 'wal' asynchronously
        set -l wal_seq (cat ${config.xdg.cacheHome}/wal/sequences)""
        echo -e $wal_seq &
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.shellAliases.catToBat {
      programs.bat = {
        enable = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.shellAliases.grepToRipgrep {
      programs.ripgrep = {
        enable = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
