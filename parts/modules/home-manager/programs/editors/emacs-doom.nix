# --- parts/modules/home-manager/programs/editors/emacs-doom.nix
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
  self',
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) isModuleLoadedAndEnabled mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.editors.emacs-doom;
  _ = mkOverrideAtHmModuleLevel;

  impermanenceCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
  pathToRelative = strings.removePrefix "${config.home.homeDirectory}/";

  emacsPkg = with pkgs; ((emacsPackagesFor emacs-unstable).emacsWithPackages (epkgs: [epkgs.vterm]));
in {
  options.tensorfiles.hm.programs.editors.emacs-doom = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    impermanence = {enable = mkImpermanenceEnableOption;};

    repoUrl = mkOption {
      type = str;
      default = "https://github.com/doomemacs/doomemacs";
      description = mdDoc ''
        TODO
      '';
    };

    configRepoUrl = mkOption {
      type = str;
      # default = "git@github.com:tsandrini/.doom.d.git";
      default = "https://github.com/tsandrini/.doom.d.git";
      description = mdDoc ''
        TODO
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = with pkgs; [
        ## Emacs itself
        binutils # native-comp needs 'as', provided by this
        # 28.2 + native-comp
        emacsPkg

        ## Doom dependencies
        git
        (ripgrep.override {withPCRE2 = true;})
        gnutls # for TLS connectivity

        ## Optional dependencies
        fd # faster projectile indexing
        imagemagick # for image-dired
        # (mkIf (config.programs.gnupg.agent.enable) # TODO
        #   pinentry_emacs) # in-emacs gnupg prompts
        zstd # for undo-fu-session/undo-tree compression

        ## Module dependencies
        # :checkers spell
        (aspellWithDicts (ds: with ds; [en cs en-computers en-science]))
        # :tools editorconfig
        editorconfig-core-c # per-project style config
        # :tools lookup & :lang org +roam
        sqlite
        # :lang latex & :lang org (latex previews)
        texlive.combined.scheme-medium
        # :lang beancount
        fava # HACK Momentarily broken on nixos-unstable
        nodejs-slim
        graphviz
        dockfmt

        # fonts
        emacs-all-the-icons-fonts
        (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
        (python311.withPackages (ps: with ps; [grip pyflakes isort pipenv nose pytest self'.packages.my_cookies]))
        self'.packages.my_cookies
        pandoc
        discount
        html-tidy
        # dockfmt
      ];

      services.emacs = {
        enable = _ true;
        package = emacsPkg;
        startWithUserSession = _ "graphical";
      };

      home.sessionPath = ["${config.xdg.configHome}/emacs/bin"];

      home.activation.installDoomEmacs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d "${config.xdg.configHome}/emacs" ]; then
           ${getExe pkgs.git} clone --depth=1 --single-branch "${cfg.repoUrl}" "${config.xdg.configHome}/emacs"
        fi
        if [ ! -d "${config.xdg.configHome}/doom" ]; then
           ${getExe pkgs.git} clone "${cfg.configRepoUrl}" "${config.xdg.configHome}/doom"
        fi
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [
          (pathToRelative "${config.xdg.configHome}/emacs")
          (pathToRelative "${config.xdg.configHome}/doom")
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
