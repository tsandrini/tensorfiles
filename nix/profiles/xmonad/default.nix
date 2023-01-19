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

  services.getty.autologinUser = _ user;

  services.xserver = {
    enable = true;
    libinput.enable = _ true;

    displayManager = {
      defaultSession = _ "home-manager";
      lightdm.enable = _ false;
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

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      haskellPackages.xmobar
      alacritty
      picom
      dmenu-rs
      pywal
      alacritty
    ];

    systemd.user.services.startx-service = {
      Unit = {
        Description = _ "X11 simple session starter";
        After = [ "graphical.target" "systemd-user-sessions.service" ];
      };
      Service = {
        User = _ user;
        WorkingDirectory = _ "$HOME";
        PAMName = _ "login";
        Environment = _ "XDG_SESSION_TYPE=x11";
        TTYPath = _ "/dev/tty8";
        StandardInput = _ "tty";
        # UnsetEnvironment = "TERM";
        UtmpIdentifier = _ "tty8";
        UtmpMode = _ "user";
        StandardOutput = _ "journal";
        ExecStartPre = _ "chvt 8";
        ExecStart = _ "startx -- vt8 -keeptty -verbose 3 -logfile /dev/null";
        # Restart = _ "Always"; # TODO probably not needed
        # RestartSec = _ "3";
      };
      Install = {
        WantedBy = [ "graphical.target" ];
      };
    };

    xsession = {
      enable = _ true;
      scriptPath = _ ".xinitrc";

      # TODO should investigate more probably
      windowManager.command = lib.mkOverride 50 "exec xmonad";
      windowManager.xmonad = {
        enable = _ true;
        config = _ ./xmonad.hs;
        enableContribAndExtras = _ true;
      };

    };
  };
}
