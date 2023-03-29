# --- profiles/dmenu-pywaled.nix
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
in {
  home-manager.users.${user} = {
    home.packages = with pkgs; [ dunst ];

    # Setup general templates
    home.file."${cfg.xdg.configHome}/wal/templates/dunstrc".source =
      _ ./templates/dunstrc;
    systemd.user.tmpfiles.rules = [
      "L ${cfg.xdg.configHome}/dunst/dunstrc - - - - ${cfg.xdg.cacheHome}/wal/dunstrc"
    ];

    # simple hack, create a blank file so home-manager will set up the dir
    # structure for us
    home.file."${cfg.xdg.configHome}/dunst/blank".text = _ "";
  };
}
