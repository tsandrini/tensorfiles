# --- lib/strings.nix
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

  /* Given an absolute path to a file, return the dirname of that file.

     *Type*: `dirnameFromPath :: Path -> Path`

     Example:
     ```nix title="Example" linenums="1"
     dirnameFromPath "/etc/myDir/file.nix"
      => "/etc/myDir"
      ```
  */
  dirnameFromPath =
    # (Path) Absolute path to a given file
    dir:
    trivial.pipe dir [ toString (strings.splitString "/") lists.last ];
}