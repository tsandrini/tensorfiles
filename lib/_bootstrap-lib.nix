# --- lib/_bootstrap-lib.nix
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
with builtins; rec {

  # This file should provide the bare minimum to bootstrap the lib, namely the
  # mapModules' function to enable properly loading the library files and its
  # functions

  mapFilterAttrs' = pred: f: attrs: filterAttrs pred (mapAttrs' f attrs);

  mapModules' = dir: fn:
    mapFilterAttrs'
    (n: v: v != null && !(hasPrefix "_" n) && !(hasPrefix ".git" n)) (n: v:
      let path = "${toString dir}/${n}";
      in if v == "directory" && pathExists "${path}/default.nix" then
        nameValuePair n (fn path)
      else if v == "directory" then
        nameValuePair n (mapModules' path fn)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n then
        nameValuePair (removeSuffix ".nix" n) (fn path)
      else
        nameValuePair "" null) (readDir dir);
}
