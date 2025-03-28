# --- flake-parts/modules/nixos/services/x11/desktop-managers/startx-home-manager.nix
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
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.services.x11.desktop-managers.startx-home-manager;
  _ = mkOverrideAtModuleLevel;
in
{
  options.tensorfiles.services.x11.desktop-managers.startx-home-manager = {
    enable = mkEnableOption ''
      Enable NixOS module that sets up the simple startx X11 displayManager with
      home-manager as the default session. This can be useful in cases where you
      want to delegate the X11 userspace completely to the user as well as its
      configuration instead of clogging your base NixOS setup.

      References
      - https://wiki.archlinux.org/title/xinit
      - https://www.x.org/releases/X11R7.6/doc/man/man1/startx.1.xhtml
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.xserver = {
        enable = _ true;
        libinput.enable = _ true;

        displayManager = {
          defaultSession = _ "home-manager";
          startx.enable = _ true;
        };

        desktopManager.session = [
          {
            name = "home-manager";
            start = ''
              ${pkgs.runtimeShell} $HOME/.xinitrc &
              waitPID=$!
            '';
          }
        ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
