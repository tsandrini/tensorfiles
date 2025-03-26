# --- flake-parts/lib/modules.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
{ lib, mapFilterAttrs }:
with lib;
with builtins;
rec {
  # <nixpkgs>/lib/modules.nix priorities:
  # mkOptionDefault = 1500: priority of option defaults
  # mkDefault = 1000: used in config sections of non-user modules to set a default
  # mkImageMediaOverride = 60:
  # mkForce = 50:
  # mkVMOverride = 10: used by ‘nixos-rebuild build-vm’

  /*
    mkOverride function with a preset priority set for all of the
    home-manager modules.

    *Type*: `mkOverrideAtModuleLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtNixvimModuleLevel = mkOverride 900;

  /*
    mkOverride function with a preset priority set for all of the
    home-manager profile modules.

    *Type*: `mkOverrideAtNixvimProfileLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtNixvimProfileLevel = mkOverride 800;

  /*
    mkOverride function with a preset priority set for all of the
    home-manager modules.

    *Type*: `mkOverrideAtModuleLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtHmModuleLevel = mkOverride 700;

  /*
    mkOverride function with a preset priority set for all of the
    home-manager profile modules.

    *Type*: `mkOverrideAtHmProfileLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtHmProfileLevel = mkOverride 600;

  /*
    mkOverride function with a preset priority set for all of the nixos
    modules.

    *Type*: `mkOverrideAtModuleLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtModuleLevel = mkOverride 500;

  /*
    mkOverride function with a preset priority set for all of the nixos
    profiles, that is, modules that preconfigure other modules.

    *Type*: `mkOverrideAtProfileLevel :: AttrSet a -> { _type :: String; priority :: Int; content :: AttrSet a; }`
  */
  mkOverrideAtProfileLevel = mkOverride 400;

  /*
    Recursively checks the presence of a nixos/home-manager module and whether
    its enabled.

    One might ask why not `?` or `hasAttr` instead?
    1. The `?` operator is indeed able to handle nested attributes, however, I've
       had some errors while linting and running the `check` command during
       development, which seems to be due to the inline direct syntax with a
       potentially nonexisting attributes.
    2. The `hasAttr` takes a string identifier instead, which is more safe, however,
        it doesn't support nested attributes.

    The solution is then to construct a recursive traverse over the identifier
    using the `hasAttr` function.

    *Type*: `isModuleLoadedAndEnabled :: AttrSet -> String -> Bool`
  */
  isModuleLoadedAndEnabled =
    cfg: identifier:
    let
      aux =
        acc: parts:
        let
          elem = head parts;
          rest = tail parts;
        in
        if length rest == 0 then
          (hasAttr elem acc) && (hasAttr "enable" acc.${elem}) && acc.${elem}.enable
        else
          (hasAttr elem acc) && (aux acc.${elem} rest);
    in
    aux cfg (splitString "." identifier);

  /*
    Recursively read a directory and apply a provided function to every `.nix`
    file. Returns an attrset that reflects the filenames and directory
    structure of the root.

    Notes:

     1. Files and directories starting with the `_` or `.git` prefix will be completely
        ignored.

     2. If a directory with a `myDir/default.nix` file will be encountered,
        the function will be applied to the `myDir/default.nix` file
        instead of recursively loading `myDir` and applying it to every file.

    *Type*: `mapModules :: Path -> (Path -> AttrSet a) -> { name :: String; value :: AttrSet a; }`

    Example:
    ```nix title="Example" linenums="1"
    mapModules ./modules import
      => { hardware = { moduleA = { ... }; }; system = { moduleB = { ... }; }; }

    mapModules ./hosts (host: mkHostCustomFunction myArg host)
      => { hostA = { ... }; hostB = { ... }; }
    ```
  */
  mapModules =
    # (Path) Root directory on which should the recursive mapping be applied
    dir:
    # (Path -> AttrSet a) Function that transforms node paths to their custom attrsets
    fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n) && !(hasPrefix ".git" n)) (
      n: v:
      let
        path = "${toString dir}/${n}";
      in
      if v == "directory" && pathExists "${path}/default.nix" then
        nameValuePair n (fn path)
      else if v == "directory" then
        nameValuePair n (mapModules path fn)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n then
        nameValuePair (removeSuffix ".nix" n) (fn path)
      else
        nameValuePair "" null
    ) (readDir dir);

  # /*
  #   Custom nixpkgs constructor. Its purpose is to import provided nixpkgs
  #   while setting the target platform and all over the needed overlays.

  #   *Type*: `mkNixpkgs :: AttrSet -> String -> [(AttrSet -> AttrSet -> AttrSet)] -> Attrset`

  #   Example:
  #   ```nix title="Example" linenums="1"
  #   mkNixpkgs inputs.nixpkgs "x86_64-linux" []
  #     => { ... }

  #   mkNixpkgs inputs.nixpkgs "aarch64-linux" [ (final: prev: {
  #     customPkgs = inputs.customPkgs { pkgs = final; };
  #   }) ]
  #     => { ... }
  #   ```
  # */
  # mkNixpkgs =
  #   # (AttrSet) TODO (this is probably not an actual attrset?)
  #   pkgs:
  #   # (String) System string identifier (eg: "x86_64-linux", "aarch64-linux", "aarch64-darwin")
  #   system:
  #   # ([AttrSet -> AttrSet -> AttrSet]) Extra overlays that should be applied to the created pkgs
  #   extraOverlays:
  #   import pkgs {
  #     inherit system;
  #     config.allowUnfree = true;
  #     hostPlatform = system;
  #     overlays =
  #       let
  #         pkgsOverlay = _final: _prev: { tensorfiles = inputs.self.packages.${system}; };
  #       in
  #       [ pkgsOverlay ] ++ extraOverlays;
  #   };

  mkDummyDerivation =
    args@{ stdenv, ... }:
    let
      finalArgs = rec {
        name = "dummy-derivation";
        version = "not-for-build";
        src = null;

        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          mkdir -p /build
          touch /build/in
        '';

        installPhase = ''
          mkdir -p $out
          cp /build/in $out
        '';

        meta = {
          homepage = "https://github.com/tsandrini/tensorfiles";
          description = "Dummy package used for ${name} -- not for build";
          platforms = [ ];
          maintainers = [ ];
        };
      } // args;
    in
    stdenv.mkDerivation finalArgs;
}
