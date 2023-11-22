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
{lib, ...}:
with lib;
with builtins; rec {
  /*
  Apply a map to every attribute of an attrset and then filter the resulting
  attrset based on a given predicate function.

  *Type*: `mapFilterAttrs :: (AttrSet b -> Bool) -> (AttrSet a -> AttrSet b) -> AttrSet a -> AttrSet b`
  */
  mapFilterAttrs =
    # (AttrSet b -> Bool) Predicate used for filtering
    pred:
    # (AttrSet a -> AttrSet b) Function used for transforming the given AttrSets
    f:
    # (AttrSet a) Initial attrset
    attrs:
      filterAttrs pred (mapAttrs' f attrs);

  /*
  Recursively merges a list of attrsets.

  *Type*: `mergeAttrs :: [AttrSet] -> AttrSet`

  Example:
  ```nix title="Example" linenums="1"
  mergeAttrs [
   { keyA = 1; keyB = 3; }
   { keyB = 10; keyC = "hey"; nestedKey = { A = null; }; }
   { nestedKey = { A = 3; B = 4; }; }
  ]
  => { keyA = 1; keyB = 10; keyC = "hey"; nestedKey = { A = 3; B = 4; };}
  ```
  */
  mergeAttrs =
    # ([AttrSet]) The list of attrsets
    attrs:
      foldl' (acc: elem: acc // elem) {} attrs;

  /*
  Given a list of elements, applies a transformation to each of the element
  to an attrset and then recursively merges the resulting attrset.

  *Type*: `mapToAttrsAndMerge :: [a] -> (a -> AttrSet) -> AttrSet`

  Example:
  ```nix title="Example" linenums="1"
  mapToAttrsAndMerge [ 1 2 3 ] (x: { "key_${toString x}": x * x })
    => { "key_1" = 1; "key_2" = 4; "key_3" = 9; }
  ```
  */
  mapToAttrsAndMerge =
    # ([a]) Initial list of elements
    list:
    # (a -> AttrSet) Function used for transforming the initial elements to attrsets
    f:
      mergeAttrs (map f list);

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
  flatten =
    # (AttrSet a) Initial nested attrset
    attrs:
      collect (x: !isAttrs x) attrs;

  /*
  Performs a `groupBy` element based grouping operation on nested attrset.

  Isn't natively supported so the strategy is to first convert the attrset
  into a list of `nameValuePair`s and then perform the `groupBy` on
  `(item: item.value)`. After a successful grouping the list is converted back
  to an attrset

  Note: This function should work with arbitrary objects as long as the values
  themselves are not nested again -- for arbitrarily large nests you should instead
  apply this function recursively.

  *Type*: `groupAttrsetBySublistElems :: AttrSet a(b) -> AttrSet b(a)`

  Example:
  ```nix title="Example" linenums="1"
  groupAttrsetBySublistElems {
  pkg1 = [ "aarch64_linux" "x86_64-linux" ];
  pkg2 = [ "x86_64-linux" ];
  pkg3 = [ "aarch64-linux" ]
  }
   => { "aarch64-linux" = [ "pkg1" "pkg3" ]; "x86_64-linux" = [ "pkg1" "pkg2" ]; }
  ```
  */
  groupAttrsetBySublistElems =
    # (AttrSet a(b)) The initial nested attrset
    inputAttrset: let
      flattened =
        concatMap
        (name: map (value: nameValuePair name value) inputAttrset.${name})
        (attrNames inputAttrset);
      grouped = groupBy (item: item.value) flattened;
    in
      listToAttrs (map (value: let
        names = map (item: item.name) grouped.${value};
      in
        nameValuePair value names) (attrNames grouped));

  /*
  Recursively checks the presence of a an attribute using `hasAttr`

  One might ask why not `?` or `hasAttr` instead?
  1. The `?` operator is indeed able to handle nested attributes, however, I've
     had some errors while linting and running the `check` command during
     development, which seems to be due to the inline direct syntax with a
     potentially nonexisting attributes.
  2. The `hasAttr` takes a string identifier instead, which is more safe, however,
      it doesn't support nested attributes.

  The solution is then to construct a recursive traverse over the identifier
  using the `hasAttr` function.

  *Type*: `nestedHasAttr:: AttrSet -> String -> Bool`
  */
  nestedHasAttr = attr: identifier: let
    aux = acc: parts: let
      elem = head parts;
      rest = tail parts;
    in
      if length rest == 0
      then (hasAttr elem acc)
      else (hasAttr elem acc) && (aux acc.${elem} rest);
  in
    aux attr (splitString "." identifier);
}
