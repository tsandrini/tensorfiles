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
{
  pkgs,
  lib,
  self,
  inputs,
  projectPath ? ./..,
  secretsPath ? (projectPath + "/secrets"),
  user ? "root",
  ...
}: let
  inherit (self.attrsets) mapFilterAttrs mergeAttrs groupAttrsetBySublistElems;
  inherit (self.strings) dirnameFromPath;
in
  with lib;
  with builtins; rec {
    # <nixpkgs>/lib/modules.nix priorities:
    # mkOptionDefault = 1500: priority of option defaults
    # mkDefault = 1000: used in config sections of non-user modules to set a default
    # mkImageMediaOverride = 60:
    # mkForce = 50:
    # mkVMOverride = 10: used by ‘nixos-rebuild build-vm’

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
        mapFilterAttrs
        (n: v: v != null && !(hasPrefix "_" n) && !(hasPrefix ".git" n)) (n: v: let
          path = "${toString dir}/${n}";
        in
          if v == "directory" && pathExists "${path}/default.nix"
          then nameValuePair n (fn path)
          else if v == "directory"
          then nameValuePair n (mapModules path fn)
          else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
          then nameValuePair (removeSuffix ".nix" n) (fn path)
          else nameValuePair "" null) (readDir dir);

    /*
    Custom nixpkgs constructor. Its purpose is to import provided nixpkgs
    while setting the target platform and all over the needed overlays.

    *Type*: `mkNixpkgs :: AttrSet -> String -> [(AttrSet -> AttrSet -> AttrSet)] -> Attrset`

    Example:
    ```nix title="Example" linenums="1"
    mkNixpkgs <nixpkgs> "x86_64-linux" []
      => { ... }

    mkNixpkgs inputs.nixpkgs "aarch64-linux" [ (final: prev: {
      customPkgs = inputs.customPkgs { pkgs = final; };
    }) ]
      => { ... }
    ```
    */
    mkNixpkgs =
      # (AttrSet) TODO (this is probably not an actual attrset?)
      pkgs:
      # (String) System string identifier (eg: "x86_64-linux", "aarch64-linux", "aarch64-darwin")
      system:
      # ([AttrSet -> AttrSet -> AttrSet]) Extra overlays that should be applied to the created pkgs
      extraOverlays:
        import pkgs {
          inherit system;
          config.allowUnfree = true;
          hostPlatform = system;
          overlays = let
            pkgsOverlay = final: prev: {
              tensorfiles = inputs.self.packages.${system};
            };
            nurOverlay = final: prev: {
              nur = import inputs.nur {pkgs = final;};
            };
          in
            [pkgsOverlay]
            ++ (optional (hasAttr "nur" inputs) nurOverlay)
            ++ (attrValues inputs.self.overlays)
            ++ extraOverlays;
        };

    /*
    Custom host (that is, nixosSystem) constructor. It expects a target host
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

    *Type*: `mkHost :: Path -> Attrset`
    */
    mkHost =
      # (Path) Path to the root directory further providing the "system" and "default.nix" files
      dir: let
        hostName = dirnameFromPath dir;
        system = removeSuffix "\n" (readFile "${dir}/system");
        systemPkgs = mkNixpkgs inputs.nixpkgs system [];
        secretsAttrset =
          if pathExists (secretsPath + "/secrets.nix")
          then (import (secretsPath + "/secrets.nix"))
          else {};
      in
        lib.nixosSystem {
          inherit system;
          pkgs = systemPkgs;
          specialArgs = {
            inherit
              inputs
              lib
              system
              user
              hostName
              projectPath
              secretsPath
              secretsAttrset
              ;
            host.hostName = hostName;
            # lintCompatibility = false;
          };
          modules = [
            {
              nixpkgs.pkgs = mkDefault systemPkgs;
              networking.hostName = hostName;
            }
            (projectPath + "/modules/profiles/_load-all-modules.nix")
            dir
          ];
        };

    /*
    Given a filepath, it will try to parse a list of platforms from the
    header (first line) of the provided file in the following format

    ```nix linenums="1"
    # platforms: aarch64-linux, x86_64-linux
    # rest of the file ...
    # ...
    ```

    In case that the provided file doesn't containt any platform specification
    it will simply return an empty list.

    *Type*: `parsePlatformHeader :: Path -> [String]`

    Example:
    ```nix title="Example" linenums="1"
    parsePlatformHeader example-file.nix
      => [ "aarch64-linux" "x86_64-linux" ]
    ```
    */
    parsePlatformHeader =
      # (Path) Path to the file whose platform header should be parsed
      file: let
        fileContent = readFile file;
        lines = splitString "\n" fileContent;
        header = replaceStrings [" "] [""] (head lines);
      in (
        if (hasPrefix "#platforms:" header)
        then splitString "," (removePrefix "#platforms:" header)
        else []
      );

    /*
    Returns a dummy derivation with a given name as and a platform
    specific builder. Useful when constructing certain defaults or general
    debugging. The resulting derivation can be compiled without errors, but
    obviously doesn't produce any nontrivial output.

    *Type*: `mkDummyDerivation :: String -> String -> AttrSet a -> Package a`

    Example:
    ```nix title="Example" linenums="1"
    mkDummyDerivation "example-pkg" "aarch64-linux" {}
     => <derivation ....>

    mkDummyDerivation "example-pkg2" "x86_64-linux" { meta.license = lib.licenses.gpl20; }
     => <derivation ....>

    mkDummyDerivation "example-pkg3" "x86_64-linux" { installPhase = "mkdir -p $out && touch $out/hey"; }
     => <derivation ....>
    ```
    */
    mkDummyDerivation =
      # (String) Name of the dummy derivation
      name:
      # (String) System architecture string. This is going to be used for choosing the target derivation builder
      system:
      # (AttrSet a) An attrset with possibily any additional values that are going to be passed to the mkDerivation call
      extraArgs: let
        systemPkgs = mkNixpkgs inputs.nixpkgs system [];
        args =
          rec {
            inherit name;
            version = "not-for-build";

            # In case something tries to actually evaluate this, we have to provide
            #
            # 1. Declaratively some source?
            # 2. Minimally something to do during the installPhase
            src = ./.;
            dontBuild = true;
            installPhase = ''
              echo "DUMMY PACKAGE for ${name}" && mkdir -p $out
            '';

            meta = {
              homepage = "https://github.com/tsandrini/tensorfiles";
              description = "Dummy package used for ${name} -- not for build";
              license = licenses.mit;
              platforms = [system];
              maintainers = [];
            };
          }
          // extraArgs;
      in
        systemPkgs.stdenv.mkDerivation args;

    /*
    Custom `packages` flake output constructor.
    It recursively traverses the provided root directory and scans for packages.
    The resulting attrset is constructed in such a way to comply with the
    flake `packages` format, that is

    packages."<system>"."<name>"

    The platform package specifications will be parsed from the packages
    themselves using the `parsePlatformHeader` which reduces the overall
    amount of manual setup while still maintaining an overall pure
    declarative structure.

    *Type*: `mkPackages :: Path -> { callPackageExtraAttrs :: AttrSet a; pkgsExtraOverlays :: [ (AttrSet -> AttrSet -> AttrSet) ] } -> AttrSet b`
    */
    mkPackages =
      # (Path) Path to the root dir which should be scanned for packages
      dir: {
        # (AttrSet a) Extra arguments that should be inherit for the callPackage pattern
        callPackageExtraAttrs ? {},
        # ([(AttrSet -> AttrSet -> AttrSet)]) Extra overlays that should be applied to created the nixpkgs instance
        pkgsExtraOverlays ? [],
      }: let
        pkgsByPlatforms = groupAttrsetBySublistElems (mapModules dir (p:
          parsePlatformHeader
          (
            if pathExists "${p}/default.nix"
            then "${p}/default.nix"
            else p
          )));
        pkgPaths = mapModules dir (p: p);
      in
        genAttrs (attrNames pkgsByPlatforms) (system: let
          systemPkgs = mkNixpkgs inputs.nixpkgs system ([] ++ pkgsExtraOverlays);
        in
          mergeAttrs (map (p: {
              "${p}" =
                systemPkgs.callPackage pkgPaths.${p}
                ({inherit lib inputs;} // callPackageExtraAttrs);
            })
            pkgsByPlatforms.${system}));

    mkShells =
      # (Path) Path to the root dir which should be scanned for packages
      dir: {}: let
        pkgsByPlatforms = groupAttrsetBySublistElems (mapModules dir (p:
          parsePlatformHeader
          (
            if pathExists "${p}/default.nix"
            then "${p}/default.nix"
            else p
          )));
        pkgPaths = mapModules dir (p: p);
      in
        genAttrs (attrNames pkgsByPlatforms) (system:
          mergeAttrs (map (p: {
              "${p}" =
                import pkgPaths.${p} {inherit inputs lib system projectPath user;};
            })
            pkgsByPlatforms.${system}));
  }
