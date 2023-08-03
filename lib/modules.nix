# --- lib/modules.nix
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
{ pkgs, lib, self, inputs, user ? "root", ... }:
let
  inherit (self.attrsets) mapFilterAttrs;
  inherit (self.strings) dirnameFromPath;
in with lib;
with builtins; rec {

  # TODO maybe create lib/nixos?
  isPersistenceEnabled = cfg:
    (cfg ? tensorfiles.system.persistence)
    && (cfg.tensorfiles.system.persistence.enable);

  # TODO maybe create lib/nixos?
  isAgenixEnabled = cfg:
    (cfg ? tensorfiles.security.agenix)
    && (cfg.tensorfiles.security.agenix.enable);

  isUsersSystemEnabled = cfg:
    (cfg ? tensorfiles.system.users) && (cfg.tensorfiles.system.users.enable);

  # <nixpkgs>/lib/modules.nix priorities:
  # mkOptionDefault = 1500: priority of option defaults
  # mkDefault = 1000: used in config sections of non-user modules to set a default
  # mkImageMediaOverride = 60:
  # mkForce = 50:
  # mkVMOverride = 10: used by ‘nixos-rebuild build-vm’
  mkOverrideAtModuleLevel = mkOverride 500;
  mkOverrideAtProfileLevel = mkOverride 400;

  mapModules = dir: fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n)) (n: v:
      let path = "${toString dir}/${n}";
      in if v == "directory" && pathExists "${path}/default.nix" then
        nameValuePair n (fn path)
      else if v == "directory" then
        nameValuePair n (mapModules path fn)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n then
        nameValuePair (removeSuffix ".nix" n) (fn path)
      else
        nameValuePair "" null) (readDir dir);

  mkPkgs = pkgs: system: extraOverlays:
    import pkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = let
        pkgsOverlay = final: prev: {
          tensorfiles = inputs.self.packages.${system};
        };
        nurOverlay = final: prev: {
          nur = import inputs.nur { pkgs = final; };
        };
      in extraOverlays ++ [ pkgsOverlay nurOverlay ]
      ++ (attrValues inputs.self.overlays);
    };

  mkHost = dir:
    let
      name = dirnameFromPath dir;
      system = removeSuffix "\n" (readFile "${dir}/system");
      systemPkgs = mkPkgs inputs.nixpkgs system [ ];
    in nixosSystem {
      inherit system;
      pkgs = systemPkgs;
      specialArgs = {
        inherit inputs lib system user;
        host.hostName = name;
      };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.pkgs = systemPkgs;
          networking.hostName = name;
        }
        (dir)
      ];
    };
}
