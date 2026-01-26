# --- flake-parts/modules/home-manager/profiles/graphical-dms-niri/default.nix
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
{ localFlake, inputs }:
{
  pkgs,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    getExe
    optional
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmProfileLevel;

  cfg = config.tensorfiles.hm.profiles.graphical-dms-niri;
  _ = mkOverrideAtHmProfileLevel;
in
{
  options.tensorfiles.hm.profiles.graphical-dms-niri = {
    enable = mkEnableOption ''
      TODO
    '';

    include-nvim =
      mkEnableOption ''
        Whether the module should add nvim-ide-config to home.packages
      ''
      // {
        default = true;
      };
  };

  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;
        profiles.headless.include-nvim = _ false;

        programs = {
          newsboat.enable = _ true;
          terminals.wezterm.enable = _ true;
          browsers.firefox.enable = _ true;
          browsers.firefox.userjs.betterfox.enable = _ true;

          thunderbird.enable = _ true;

          dsearch.enable = _ true;
        };
      };

      home.packages = [
        pkgs.neovide # This is a simple graphical user interface for Neovim
      ]
      ++ (optional cfg.include-nvim localFlake.packages.${system}.nvim-ide-config);

      services.flameshot = {
        enable = _ true;
        settings = {
          General.showStartupLaunchMessage = _ false;
        };
      };

      home.shellAliases = {
        "graphical-nvim" = _ (getExe localFlake.packages.${system}.nvim-graphical-config);
        "ide-nvim" = _ (getExe localFlake.packages.${system}.nvim-ide-config);
      };

      home.sessionVariables = {
        # Default programs
        BROWSER = _ "firefox";
        TERMINAL = _ "wezterm";
        IDE = _ "nvim";
        EMAIL = _ "thunderbird";
      };

      fonts.fontconfig.enable = _ true;

      programs.dank-material-shell = {
        enable = _ true;
        niri.includes = {
          enable = _ true;
          enableSpawn = _ true; # Auto-start DMS with niri, if enabled
          # filesToInclude = [
          #   # Files under `$XDG_CONFIG_HOME/niri/dms` to be included into the new config
          #   "alttab" # Please note that niri will throw an error if any of these files are missing.
          #   "binds"
          #   "colors"
          #   "layout"
          #   "outputs"
          #   "wpblur"
          # ];
        };

        enableSystemMonitoring = _ true;
        enableVPN = _ true;
        enableDynamicTheming = _ true;
        enableAudioWavelength = _ true;
        enableCalendarEvents = _ true;
        enableClipboardPaste = _ true;
      };

      systemd.user.services.niri-flake-polkit.enable = _ false; # use dms
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
