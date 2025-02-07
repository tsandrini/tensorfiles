# --- flake-parts/modules/programs/shells/zsh/default.nix
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
  inherit (lib.strings) removePrefix;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkPywalEnableOption mkImpermanenceEnableOption;

  cfg = config.tensorfiles.hm.programs.shells.zsh;
  _ = mkOverrideAtHmModuleLevel;

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence = if impermanenceCheck then config.tensorfiles.hm.system.impermanence else { };
  pathToRelative = removePrefix "${config.home.homeDirectory}/";
in
{
  options.tensorfiles.hm.programs.shells.zsh = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the zsh shell.
    '';

    pywal = {
      enable = mkPywalEnableOption;
    };

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };

    withAutocompletions = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable autosuggestions/autocompletion related code
      '';
    };

    p10k = {
      enable =
        mkEnableOption ''
          Whether to enable the powerlevel10k theme (and plugins) related
          code.
        ''
        // {
          default = true;
        };

      cfgSrc = mkOption {
        type = types.path;
        default = ./.;
        description = ''
          Path (or ideally, path inside a derivation) for the p10k.zsh
          configuration file

          Note: This should point just to the target directory. If you
          want to change the default filename of the `p10k.zsh` file,
          modify the cfgFile option.
        '';
      };

      cfgFile = mkOption {
        type = types.str;
        default = "p10k.zsh";
        description = ''
          Potential override of the p10k.zsh config filename.
        '';
      };
    };

    oh-my-zsh = {
      enable =
        mkEnableOption ''
          Whether to enable the oh-my-zsh framework related code
        ''
        // {
          default = true;
        };

      plugins = mkOption {
        type = types.listOf types.str;
        default = [
          "git"
          "git-flow"
          "colorize"
          "colored-man-pages"
        ];
        description = ''
          oh-my-zsh plugins that are enabled by default
        '';
      };

      withFzf = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable the fzf plugin
        '';
      };
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
        [ nitch ]
        ++ (optional lsToEza eza)
        ++ (optional catToBat bat)
        ++ (optional findToFd fd)
        ++ (optional grepToRipgrep ripgrep);

      programs.zsh = {
        enable = _ true;
        syntaxHighlighting.enable = _ true;
        autosuggestion.enable = _ cfg.withAutocompletions;
        history = {
          extended = _ false;
          expireDuplicatesFirst = _ true;
          ignoreAllDups = _ true;
          ignoreDups = _ true;
          ignoreSpace = _ true;
          size = _ 1000000;
          save = _ 1000000;
        };
        # historySubstringSearch = {
        #   enable = _ true;
        #};
        oh-my-zsh = mkIf cfg.oh-my-zsh.enable {
          enable = _ true;
          plugins = cfg.oh-my-zsh.plugins ++ (optional cfg.oh-my-zsh.withFzf "fzf");
        };
        plugins = [
          (mkIf cfg.withAutocompletions {
            name = "nix-zsh-completions";
            src = pkgs.nix-zsh-completions;
            file = "share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh";
          })
          (mkIf cfg.p10k.enable {
            name = "zsh-powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          })
          (mkIf cfg.p10k.enable {
            name = "powerlevel10k-config";
            src = cfg.p10k.cfgSrc;
            file = cfg.p10k.cfgFile;
          })
        ];
        loginExtra = _ "${getExe pkgs.nitch}";
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
    (mkIf ((isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable) {
      programs.zsh.initExtra = mkBefore ''
        # Import colorscheme from 'wal' asynchronously
        # &   # Run the process in the background.
        # ( ) # Hide shell job control messages.
        (cat ${config.xdg.cacheHome}/wal/sequences &)
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.oh-my-zsh.withFzf {
      programs.fzf = {
        enable = _ true;
      };
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
    (mkIf impermanenceCheck {
      home.file."${config.xdg.cacheHome}/oh-my-zsh/.keep".enable = false;

      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        files =
          [ ".zsh_history" ]
          ++ (optional cfg.oh-my-zsh.enable (pathToRelative "${config.xdg.cacheHome}/oh-my-zsh"))
          ++ (
            if cfg.p10k.enable then
              [
                (pathToRelative "${config.xdg.cacheHome}/p10k-dump-${config.home.username}.zsh")
                (pathToRelative "${config.xdg.cacheHome}/p10k-dump-${config.home.username}.zsh.zwc")
                (pathToRelative "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh")
                (pathToRelative "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh.zwc")
              ]
            else
              [ ]
          );
        directories = optional cfg.p10k.enable (
          pathToRelative "${config.xdg.cacheHome}/p10k-${config.home.username}"
        );
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
