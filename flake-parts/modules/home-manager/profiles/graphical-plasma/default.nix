# --- flake-parts/modules/home-manager/profiles/graphical-plasma/default.nix
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

  cfg = config.tensorfiles.hm.profiles.graphical-plasma;
  _ = mkOverrideAtHmProfileLevel;
in
{
  options.tensorfiles.hm.profiles.graphical-plasma = {
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

  # imports = with inputs; [ plasma-manager.homeManagerModules.plasma-manager ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    # (import ./rc2nix.nix)
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;
        profiles.headless.include-nvim = _ false;

        # TODO nixGL requires --impure
        # hardware.nixGL.enable = _ true;

        programs = {
          newsboat.enable = _ true;
          pywal.enable = _ true;
          # terminals.kitty.enable = _ true;
          terminals.wezterm.enable = _ true;
          browsers.firefox.enable = _ true;
          browsers.firefox.userjs.betterfox.enable = _ true;

          # editors.emacs-doom.enable = _ true;
          # NOTE switched to nixvim
          # editors.neovim.lsp.enable = _ true;

          thunderbird.enable = _ true;
        };

        services = {
          pywalfox-native.enable = _ true;
        };
      };

      home.packages =
        with pkgs;
        [
          neovide # This is a simple graphical user interface for Neovim
        ]
        ++ (optional cfg.include-nvim localFlake.packages.${system}.nvim-ide-config);

      services.flameshot = {
        enable = _ true;
        settings = {
          General.showStartupLaunchMessage = _ false;
        };
      };

      services.rsibreak.enable = _ false;

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
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
