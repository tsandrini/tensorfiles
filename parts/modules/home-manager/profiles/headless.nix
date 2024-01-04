# --- parts/modules/home-manager/profiles/headless.nix
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
  self,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) mkOverrideAtHmProfileLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.profiles.headless;
  _ = mkOverrideAtHmProfileLevel;

  impermanenceCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
  # pathToRelative = strings.removePrefix "${config.home.homeDirectory}/";
in {
  options.tensorfiles.hm.profiles.headless = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    impermanence = {enable = mkImpermanenceEnableOption;};
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.minimal.enable = _ true;

        programs = {
          shells.zsh.enable = _ true;
          editors.neovim.enable = _ true;
          file-managers.yazi.enable = _ true;

          btop.enable = _ true;
          direnv.enable = _ true;
          git.enable = _ true;
          ssh.enable = _ true;
        };
      };

      home.sessionVariables = {
        # Default programs
        EDITOR = "nvim";
        VISUAL = "nvim";
        # Directory structure
        DOWNLOADS_DIR = config.home.homeDirectory + "/Downloads";
        ORG_DIR = config.home.homeDirectory + "/OrgBundle";
        PROJECTS_DIR = config.home.homeDirectory + "/ProjectBundle";
        MISC_DATA_DIR = config.home.homeDirectory + "/FiberBundle";
        # Fallbacks
        # DEFAULT_USERNAME = "tsandrini";
        # DEFAULT_MAIL = "tomas.sandrini@seznam.cz";
      };

      home.file = {
        "${config.xdg.configHome}/.blank".text = mkBefore "";
        "${config.xdg.cacheHome}/.blank".text = mkBefore "";
        "${config.xdg.dataHome}/.blank".text = mkBefore "";
        "${config.xdg.stateHome}/.blank".text = mkBefore "";

        "${config.home.sessionVariables.DOWNLOADS_DIR}/.blank".text =
          mkIf (config.home.sessionVariables.DOWNLOADS_DIR != null) (mkBefore "");
        "${config.home.sessionVariables.ORG_DIR}/.blank".text =
          mkIf (config.home.sessionVariables.ORG_DIR != null) (mkBefore "");
        "${config.home.sessionVariables.PROJECTS_DIR}/.blank".text =
          mkIf (config.home.sessionVariables.PROJECTS_DIR != null) (mkBefore "");
        "${config.home.sessionVariables.MISC_DATA_DIR}/.blank".text =
          mkIf (config.home.sessionVariables.MISC_DATA_DIR != null) (mkBefore "");
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [
          ".gnupg"
          ".ssh"
          # ".cache"
          # ".local/state"
          "Downloads"
          "OrgBundle"
          "ProjectBundle"
          "FiberBundle"
          # config.xdg.cacheHome
          # config.xdg.stateHome
          # config.home.sessionVariables.DOWNLOADS_DIR
          # config.home.sessionVariables.ORG_DIR
          # config.home.sessionVariables.PROJECTS_DIR
          # config.home.sessionVariables.MISC_DATA_DIR
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
