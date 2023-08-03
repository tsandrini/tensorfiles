# --- profiles/home-pywalfox-native.nix
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
let
  _ = lib.mkOverride 500;
  pywalfox-native = inputs.self.packages.${system}.pywalfox-native;
  pywalfox-wrapper = pkgs.writeShellScriptBin "pywalfox-wrapper" ''
    ${pywalfox-native}/bin/pywalfox start
  '';
in {

  home-manager.users.${user} = {

    home.packages = with pkgs; [ pywalfox-native ];

    home.file.".mozilla/native-messaging-hosts/pywalfox.json".text =
      builtins.replaceStrings [ "<path>" ]
      [ "${pywalfox-wrapper}/bin/pywalfox-wrapper" ] (builtins.readFile
        "${pywalfox-native}/lib/python3.10/site-packages/pywalfox/assets/manifest.json");
  };
}
