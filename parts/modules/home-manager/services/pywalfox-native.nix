# --- parts/modules/home-manager/services/pywalfox-native.nix
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
  pkgs,
  self,
  self',
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;

  cfg = config.tensorfiles.hm.services.pywalfox-native;

  inherit (self'.packages) pywalfox-native;
  pywalfox-wrapper = pkgs.writeShellScriptBin "pywalfox-wrapper" ''
    ${pywalfox-native}/bin/pywalfox start
  '';
in {
  options.tensorfiles.hm.services.pywalfox-native = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles terminals.kitty colorscheme generator.
    '');

    pkg = mkOption {
      type = package;
      default = pkgs.kitty;
      description = ''
        TODO
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [pywalfox-native];

      home.file.".mozilla/native-messaging-hosts/pywalfox.json".text =
        replaceStrings ["<path>"] ["${pywalfox-wrapper}/bin/pywalfox-wrapper"] (readFile
          "${pywalfox-native}/lib/python3.11/site-packages/pywalfox/assets/manifest.json");
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
