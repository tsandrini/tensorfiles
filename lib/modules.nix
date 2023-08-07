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

  /* Check whether the persistence system is enabled, that is whether

     1. The `tensorfiles.system.persistence` modul is imported
     2. It is also enabled

     Type:
      isPersistenceEnabled :: AttrSet -> Bool
  */
  isPersistenceEnabled = cfg:
    (cfg ? tensorfiles.system.persistence)
    && (cfg.tensorfiles.system.persistence.enable);

  /* Check whether the agenix system is enabled, that is whether

     1. The `tensorfiles.security.agenix` modul is imported
     2. It is also enabled

     Type:
      isAgenixEnabled :: AttrSet -> Bool
  */
  isAgenixEnabled = cfg:
    (cfg ? tensorfiles.security.agenix)
    && (cfg.tensorfiles.security.agenix.enable);

  /* Check whether the agenix system is enabled, that is whether

     1. The `tensorfiles.system.users` modul is imported
     2. It is also enabled

     Type:
      isUsersSystemEnabled :: AttrSet -> Bool
  */
  isUsersSystemEnabled = cfg:
    (cfg ? tensorfiles.system.users) && (cfg.tensorfiles.system.users.enable);

  /* Transforms an absolute path to a one relative to the given user home
     directory. It basically functions as a case handler for
     `lib.strings.removePreffix` to handle a variety of different cases.

      1. If you pass `cfg = config;` then the function will load the `homeDir`
         specified in the users system module (tensorfiles.system.users).
         Note that the module has to be also enabled.
      2. You can instead just pass the username directly instead, in that case
         it will remove either `/home/$user` or `/root` depending on the provided
         user.
      3. You can also just pass the `home`. In that case it behaves basically just
         like a direct call to `lib.strings.removePrefix`
      4. You can omit passing any variables, in that case the function will try to
         parse the user that has been passed for the initialization of the whole
         lib/ (if any was provided). If no user was provided in this manner, it
         will fallback to /root.

     Example:
       absolutePathToRelativeHome "/home/myUser/myDir/file.txt" { cfg = config; user = "myUser"; }
        -> "myDir/file.txt"

       absolutePathToRelativeHome "/home/myUser/myDir/file.txt" { user = "myUser"; }
        -> "myDir/file.txt"

       absolutePathToRelativeHome "/root/myDir/file.txt" { user = "root"; }
        -> "myDir/file.txt"

       absolutePathToRelativeHome "/var/myUserHome/myDir/file.txt" { home = "/var/myUserHome"; }
        -> "myDir/file.txt"

       absolutePathToRelativeHome "/home/myUser/myDir/file.txt" {} -> "myDir/file.txt"

     Type:
       absolutePathToRelativeHome :: String -> { _user :: String; home :: String; cfg :: AttrSet } -> String
  */
  absolutePathToRelativeHome = path:
    { _user ? user, home ? null, cfg ? null }:
    if (cfg != null && (isUsersSystemEnabled cfg)) then
      (strings.removePrefix
        (cfg.tensorfiles.system.users.home.settings.${_user}.homeDir + "/")
        path)
    else
      (let
        home = (if home != null then
          home
        else
          (if _user != "root" then "/home/${_user}" else "/root")) + "/";
      in (strings.removePrefix home path));

  # <nixpkgs>/lib/modules.nix priorities:
  # mkOptionDefault = 1500: priority of option defaults
  # mkDefault = 1000: used in config sections of non-user modules to set a default
  # mkImageMediaOverride = 60:
  # mkForce = 50:
  # mkVMOverride = 10: used by ‘nixos-rebuild build-vm’

  /* mkOverride function with a preset priority set for all of the nixos
     modules.

     Type:
       mkOverrideAtModuleLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }
  */
  mkOverrideAtModuleLevel = mkOverride 500;

  /* mkOverride function with a preset priority set for all of the nixos
     profiles, that is, modules that preconfigure other modules.

     Type:
       mkOverrideAtProfileLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }
  */
  mkOverrideAtProfileLevel = mkOverride 400;

  /* Recursively read a directory and apply a provided function to every `.nix`
     file. Returns an attrset that reflects the filenames and directory
     structure of the root.

     Notes:
      1. Files and directories starting with the `_` prefix will be completely
         ignored.
      2. If a directory with a `myDir/default.nix` file will be encountered,
         the function will be applied to the `myDir/default.nix` file
         instead of recursively loading `myDir` and applying it to every file.

     Example:
       mapModules ./modules import
        -> {
          hardware = {
            moduleA = { ... };
          };
          system = {
            moduleB = { ... };
          };
        }

       mapModules ./hosts (host: mkHostCustomFunction myArg host)
        -> {
          hostA = { ... };
          hostB = { ... };
        }

     Type:
       mapModules :: Path -> (Path -> AttrSet a) -> { name :: String; value :: AttrSet a; }
  */
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

  /* Custom nixpkgs constructor. Its purpose is to import provided nixpkgs
     while setting the target platform and all over the needed overlays.

     Example:
      mkPkgs <nixpkgs> "x86_64-linux" []
        -> { ... }

      mkPkgs inputs.nixpkgs "aarch64-linux" [ (final: prev: {
        customPkgs = inputs.customPkgs { pkgs = final; };
      }) ]
        -> { ... }

     Type:
       mkPkgs :: AttrSet -> String -> [(AttrSet -> AttrSet -> AttrSet)] -> Attrset
  */
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
      in [ pkgsOverlay ] ++ (optional (inputs ? nur) nurOverlay)
      ++ (attrValues inputs.self.overlays) ++ extraOverlays;
    };

  /* Custom host (that is, nixosSystem) constructor. It expects a target host
     dir path as its first argument, that is, not a `.nix` file, but a directory.
     The reasons for this are the following:

     1. Each host gets its specifically constructed version of nixpkgs for its
        target platform, which is specified in the `myHostDir/system` file.
     2. Apart from some main host `.nix` file almost every host has some
        `hardware-configuration.nix` thus implying a host directory structure
        holding atleast 2 files + the system file.

     This means that the minimal required structure for a host dir is
     - myHostDir/
       - (required) default.nix
       - (required) system
       - (optional) hardware-configuration.nix

     Type:
       mkHost :: Path -> Attrset
  */
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
