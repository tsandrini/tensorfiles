# --- profiles/xmonad-with-xmobar-pywaled/default.nix
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
  cfg = config.home-manager.users.${user};

  trayer-padding-icon = pkgs.writeShellScriptBin "trayer-padding-icon" ''
    #!/bin/sh
    # Copied from https://github.com/jaor/xmobar/issues/239#issuecomment-233206552
    # Detects the width of running trayer-srg window (xprop name 'panel')
    # and creates an XPM icon of that width, 1px height, and transparent.
    # Outputs an <icon>-tag for use in xmobar to display the generated
    # XPM icon.
    #
    # Run script from xmobar:
    # `Run Com "/where/ever/trayer-padding-icon.sh" [] "trayerpad" 10`
    # and use `%trayerpad%` in your template.


    # Function to create a transparent Wx1 px XPM icon
    create_xpm_icon () {
        timestamp=$(date)
        pixels=$(for i in `seq $1`; do echo -n "."; done)

        cat << EOF > "$2"
    /* XPM *
    static char * trayer_pad_xpm[] = {
    /* This XPM icon is used for padding in xmobar to */
    /* leave room for trayer-srg. It is dynamically   */
    /* updated by by trayer-padding-icon.sh which is run  */
    /* by xmobar.                                     */
    /* Created: ''${timestamp} */
    /* <w/cols>  <h/rows>  <colors>  <chars per pixel> */
    "$1 1 1 1",
    /* Colors (none: transparent) */
    ". c none",
    /* Pixels */
    "$pixels"
    };
    EOF
    }

    # Width of the trayer window
    width=$(xprop -name panel | grep 'program specified minimum size' | cut -d ' ' -f 5)

    # Icon file name
    iconfile="/tmp/trayer-padding-''${width}px.xpm"

    # If the desired icon does not exist create it
    if [ ! -f $iconfile ]; then
        create_xpm_icon $width $iconfile
    fi

    # Output the icon tag for xmobar
    echo "<icon=''${iconfile}/>"
  '';

in {
  services.xserver = {
    enable = _ true;
    libinput.enable = _ true;

    displayManager = {
      defaultSession = _ "home-manager";
      lightdm.enable = _ false;
      startx.enable = _ true;
    };

    desktopManager.session = [{
      name = "home-manager";
      start = ''
        ${pkgs.runtimeShell} $HOME/.xinitrc &
        waitPID=$!
      '';
    }];
  };

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      nerdfonts
      haskellPackages.xmobar
      feh
      pywal
      alacritty
      i3lock-fancy-rapid
      autorandr
      trayer-padding-icon
    ];

    xsession = {
      enable = _ true;
      scriptPath = _ ".xinitrc";

      windowManager.command = lib.mkOverride 50 "exec xmonad";
      windowManager.xmonad = {
        enable = _ true;
        config = _ ./xmonad.hs;
        enableContribAndExtras = _ true;
      };
    };

    # xmobar source
    home.file."${cfg.xdg.configHome}/wal/templates/xmobarrc".source =
      _ ./templates/xmobarrc;
    systemd.user.tmpfiles.rules = [
      "L ${cfg.xdg.configHome}/xmobar/xmobarrc - - - - ${cfg.xdg.cacheHome}/wal/xmobarrc"
    ];

    # xmobar trayer padding icon generator
    # home.file."${cfg.xdg.configHome}/xmobar/trayer-padding-icon.sh".source =
    #   _ trayerPaddingIcon;

    # lil haskell icon ^^
    home.file."${cfg.home.homeDirectory}/.xmonad/xpm/haskell_20.xpm".source =
      _ ./xpm/haskell_20.xpm;
  };
}
