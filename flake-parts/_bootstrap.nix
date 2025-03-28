# --- flake-parts/_bootstrap.nix
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
{ lib }:
rec {
  # This nix file is used to minimally set up and bootstrap the `loadParts`
  # function which is then used to load all the modules in the
  #  `./flake-parts` directory. The user also has the option to remove
  # this file and directly load the `loadParts` function from
  # the `lib` attribute of the `github:tsandrini/flake-parts-builder`
  # flake, however, that brings an additional dependency to the project,
  # which may be undesirable for some and isn't really necessary.
  loadParts = dir: flatten (mapModules dir (x: x));

  /*
    Recursively flattens a nested attrset into a list of just its values.

    *Type*: `flatten :: AttrSet a -> [a]`

    Example:
    ```nix title="Example" linenums="1"
    flatten {
      keyA = 10;
      keyB = "str20";
      keyC = {
        keyD = false;
        keyE = {
          a = 10;
          b = "20";
          c = false;
        };
      };
    }
     => [ 10 "str20" false 10 "20" false ]
    ```
  */
  flatten = attrs: lib.collect (x: !lib.isAttrs x) attrs;

  /*
    Apply a map to every attribute of an attrset and then filter the resulting
    attrset based on a given predicate function.

    *Type*: `mapFilterAttrs :: (AttrSet b -> Bool) -> (AttrSet a -> AttrSet b) -> AttrSet a -> AttrSet b`
  */
  mapFilterAttrs =
    pred: f: attrs:
    lib.filterAttrs pred (lib.mapAttrs' f attrs);

  /*
    Recursively read a directory and apply a provided function to every `.nix`
    file. Returns an attrset that reflects the filenames and directory
    structure of the root.

    Notes:

     1. Files and directories starting with the `_` or `.git` prefix will be
        completely ignored.

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
    dir: fn:
    mapFilterAttrs (n: v: v != null && !(lib.hasPrefix "_" n) && !(lib.hasPrefix ".git" n)) (
      n: v:
      let
        path = "${toString dir}/${n}";
      in
      if v == "directory" && builtins.pathExists "${path}/default.nix" then
        lib.nameValuePair n (fn path)
      else if v == "directory" then
        lib.nameValuePair n (mapModules path fn)
      else if v == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n then
        lib.nameValuePair (lib.removeSuffix ".nix" n) (fn path)
      else
        lib.nameValuePair "" null
    ) (builtins.readDir dir);
}
