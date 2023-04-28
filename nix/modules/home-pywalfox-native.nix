# --- modules/home-pywalfox-native.nix
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
{ config, pkgs, lib, inputs, system, user, ... }:
with lib;
let
  cfg = config.tensormodules.home-pywalfox-native;
  pywalfox-native = inputs.self.packages.${system}.pywalfox-native;
in {
  options.tensormodules.home-pywalfox-native = with types; {
    enable = mkEnableOption "Pywalfox-native messenger module";
  };

  config = mkIf cfg.enable {
    # assertions = [{
    #   assertion = (!cfg.systemd || !cfg.grub) && (cfg.systemd || cfg.grub);
    #   message = "(Exactly) one bootloader needs to be provided";
    # }];

    home-manager.users.${user} = {

      home.packages = with pkgs; [ pywalfox-native ];

      systemd.user.services.pywalfox-native = {
        Unit = {
          Description = "Native app used alongside the Pywalfox addon.";
          Documentation = [ "https://github.com/Frewacom/pywalfox-native" ];
        };
        Service = {
          ExecStartPre = "python3 pywalfox install";
          ExecStart = "python3 pywalfox start";
          ExecStartPost = "python3 pywalfox uninstall";
          Restart = "on-failure";
          RestartSec = "5";
        };
        # Install.WantedBy = [ "default.target" ];
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
