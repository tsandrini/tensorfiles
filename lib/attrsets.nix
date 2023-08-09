# --- lib/attrsets.nix
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

  /* Apply a map to every attribute of an attrset and then filter the resulting
     attrset based on a given predicate function.

     Type: mapFilterAttrs :: (AttrSet b -> Bool) -> (AttrSet a -> AttrSet b) -> AttrSet a -> AttrSet b
  */
  mapFilterAttrs =
    # Predicate used for filtering
    pred:
    # Transformer
    f:
    # Attrs
    attrs:
    filterAttrs pred (mapAttrs' f attrs);

  /* Recursively merges a list of attrsets.
     TODO **testing bold**
     TODO *testing italic*

     > testing quotation?

     ```
     testing code block?
     ```

     Type: mergeAttrs :: [AttrSet] -> AttrSet

     Example:
       mergeAttrs [
        { keyA = 1; keyB = 3; }
        { keyB = 10; keyC = "hey"; nestedKey = { A = null; }; }
        { nestedKey = { A = 3; B = 4; }; }
       ]
       => {
           keyA = 1;
           keyB = 10;
           keyC = "hey";
           nestedKey = {
             A = 3;
             B = 4;
           };
         }
  */
  mergeAttrs =
    # eh dunno test test
    attrs:
    foldl' (acc: elem: acc // elem) { } attrs;

  /* Given a list of elements, applies a transformation to each of the element
     to an attrset and then recursively merges the resulting attrset.

     Example:
       mapToAttrsAndMerge [ 1 2 3 ] (x: { "key_${toString x}": x * x })
       ->
        {
          "key_1" = 1;
          "key_2" = 4;
          "key_3" = 9;
        }

     Type:
      mapToAttrsAndMerge :: [a] -> (a -> AttrSet) -> AttrSet
  */
  mapToAttrsAndMerge = list: f: mergeAttrs (map f list);

  /* Recursivelly flattens a nested attrset into a list of just its values.

     Example:
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
         -> [ 10 "str20" false 10 "20" false ]

     Type:
       flatten :: AttrSet a -> [a]
  */
  flatten = attrs: collect (x: !isAttrs x) attrs;
}
