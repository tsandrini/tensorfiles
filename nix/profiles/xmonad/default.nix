# --- profiles/xmonad/default.nix
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

{ config, pkgs, lib, inputs, user, ... }:

let
  _ = lib.mkOverride 500;
in {

  services.xserver = {
    enable = true;
    libinput.enable = true;
    displayManager.defaultSession = "none+xmonad";
    displayManager.lightdm = {
      enable = true;
      greeters.slick.enable = true;
    };

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./xmonad.hs;
    };
  };

  # services.getty.autologinUser = user;
  # services.xserver.enable = true;
  # services.xserver.displayManager.defaultSession = "home-manager";
  # services.xserver.libinput.enable = true;
  # services.xserver.desktopManager.session = [
  #   {
  #     name = "home-manager";
  #     start = ''
  #       ${pkgs.runtimeShell} $HOME/.hm-xsession &
  #       waitPID=$!
  #     '';
  #   }
  # ];

  # home-manager.users.${user} = {
  #   home.packages = with pkgs; [
  #     pywal
  #     xmobar
  #   ];

  #   xsession.enable = true;
  #   xsession.scriptPath = ".hm-xsession";
  #   xsession.windowManager.xmonad.enable = true;
  #   #xsession.windowManager.xmonad.config = ./xmonad.hs;
  #   xsession.windowManager.xmonad.enableContribAndExtras = true;
  # };

}
