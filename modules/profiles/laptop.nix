# --- modules/profiles/laptop.nix
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
{ config, lib, pkgs, inputs, user ? "root", ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.laptop;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.profiles.laptop = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the laptop system profile.

        **TODO**: decouple this into a graphical + xmonad + persitence profiles
      '');
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      tensorfiles.profiles.headless.enable = _ true;

      tensorfiles.misc.gtk.enable = _ true;

      tensorfiles.programs.newsboat.enable = _ true;
      tensorfiles.programs.dmenu.enable = _ true;
      tensorfiles.programs.file-managers.lf.enable = _ true;
      tensorfiles.programs.file-managers.lf.home.settings."tsandrini".previewer.backend =
        _ "kitty";
      tensorfiles.programs.pywal.enable = _ true;
      tensorfiles.programs.terminals.kitty.enable = _ true;
      tensorfiles.programs.terminals.alacritty.enable = _ true;
      tensorfiles.programs.browsers.firefox.enable = _ true;

      tensorfiles.security.agenix.enable = _ true;
      tensorfiles.services.dunst.enable = _ true;

      tensorfiles.services.pywalfox-native.enable = _ true;
      tensorfiles.services.x11.picom.enable = _ true;
      tensorfiles.services.x11.redshift.enable = _ true;
      tensorfiles.services.x11.window-managers.xmonad.enable = _ true;

      tensorfiles.system.persistence.enable = _ true;

      tensorfiles.system.persistence.btrfsWipe = {
        enable = _ true;
        rootPartition = _ "/dev/mapper/enc";
      };

      # TODO fix this
      # Init also the root user even if not used elsewhere
      tensorfiles.system.users.home.settings."root" = { isSudoer = _ false; };
      tensorfiles.system.users.home.settings."tsandrini" = {
        isSudoer = _ true;
        email = _ "tomas.sandrini@seznam.cz";
      };

      tensorfiles.misc.xdg.home.settings."root" = { };
      tensorfiles.misc.xdg.home.settings."tsandrini" = { };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
