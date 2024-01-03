# --- parts/modules/programs/shells/zsh/default.nix
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
  config,
  lib,
  pkgs,
  self,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.shells.zsh;
  _ = mkOverrideAtHmModuleLevel;

  impermanenceCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
in {
  options.tensorfiles.hm.programs.shells.zsh = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the zsh shell.
    '');

    pywal = {enable = mkPywalEnableOption;};

    impermanence = {enable = mkImpermanenceEnableOption;};

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
        default = ["git" "git-flow" "colorize" "colored-man-pages"];
        description = mdDoc ''
          oh-my-zsh plugins that are enabled by default
        '';
      };

      withFzf = mkOption {
        type = bool;
        default = true;
        description = mdDoc ''
          Whether to enable the fzf plugin
        '';
      };
    };

    shellAliases = {
      lsToEza = mkOption {
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
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = with pkgs;
      with cfg.shellAliases;
        [nitch]
        ++ (optional lsToEza eza)
        ++ (optional catToBat bat)
        ++ (optional findToFd fd)
        ++ (optional grepToRipgrep ripgrep)
        ++ (optional cfg.oh-my-zsh.withFzf fzf);

      programs.zsh = {
        enable = _ true;
        syntaxHighlighting.enable = _ true;
        enableAutosuggestions = _ cfg.withAutocompletions;
        oh-my-zsh = mkIf cfg.oh-my-zsh.enable {
          enable = _ true;
          plugins =
            cfg.oh-my-zsh.plugins
            ++ (optional cfg.oh-my-zsh.withFzf "fzf");
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
        loginExtra = _ "${pkgs.nitch}/bin/nitch";
      };

      home.shellAliases = mkMerge [
        {fetch = _ "${pkgs.nitch}/bin/nitch";}
        (mkIf cfg.shellAliases.lsToEza {
          ls = _ "${pkgs.eza}/bin/eza";
          ll =
            _
            "${pkgs.eza}/bin/eza -F --hyperlink --icons --group-directories-first -la --git --header --created --modified";
          tree =
            _
            "${pkgs.eza}/bin/eza -F --hyperlink --icons --group-directories-first -la --git --header --created --modified -T";
        })
        (mkIf cfg.shellAliases.catToBat {
          cat = _ "${pkgs.bat}/bin/bat -p --wrap=never --paging=never";
          less = _ "${pkgs.bat}/bin/bat --paging=always";
        })
        (mkIf cfg.shellAliases.findToFd {
          find = _ "${pkgs.fd}/bin/fd";
          fd = _ "${pkgs.fd}/bin/fd";
        })
        (mkIf cfg.shellAliases.grepToRipgrep {
          grep = _ "${pkgs.ripgrep}/bin/rg";
        })
        {fetch = _ "${pkgs.nitch}/bin/nitch";}
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
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        files = [".zsh_history"];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
