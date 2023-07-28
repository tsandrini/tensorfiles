# --- lib/options.nix
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
{ lib, ... }:
with lib;
with lib.types;
with builtins; rec {

  mkPersistenceEnableOption = mkOption {
    type = bool;
    default = true;
    example = false;
    description = mdDoc ''
      Whether to autoappend files/folders to the persistence system.
      For more info on the persistence system refer to the system.persistence
      NixOS module documentation.

      Note that this will get executed only if

      1. persistence.enable = true;
      2. tensorfiles.system.persistence module is loaded
      3. tensorfiles.system.persistence.enable = true;
    '';
  };
}
