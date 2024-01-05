# --- lib/nixos.nix
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
with builtins; {
  /*
  Transforms an absolute path to a one relative to the given user home
  directory. It basically functions as a case handler for
  `lib.strings.removePrefix` to handle a variety of different cases.

   1. If you pass `cfg = config;` then the function will load the `homeDir`
      specified in the users system module (tensorfiles.system.users).
      Note that the module has to be also enabled.

   2. You can instead just pass the username directly instead, in that case
      it will remove either `/home/$user` or `/root` depending on the provided user.

   3. You can also just pass the `home`. In that case it behaves basically just
      like a direct call to `lib.strings.removePrefix`

   4. You can omit passing any variables, in that case the function will try to
      parse the user that has been passed for the initialization of the whole
      lib/ (if any was provided). If no user was provided in this manner, it
      will fallback to /root.

  *Type*: `absolutePathToRelativeHome :: Path -> { _user :: String; home :: String; cfg :: AttrSet } -> String`

  Example:
  ```nix title="Example" linenums="1"
   absolutePathToRelativeHome "/home/myUser/myDir/file.txt" { cfg = config; user = "myUser"; }
     => "myDir/file.txt"

   absolutePathToRelativeHome "/home/myUser/myDir/file.txt" { user = "myUser"; }
     => "myDir/file.txt"

   absolutePathToRelativeHome "/root/myDir/file.txt" { user = "root"; }
     => "myDir/file.txt"

   absolutePathToRelativeHome "/var/myUserHome/myDir/file.txt" { home = "/var/myUserHome"; }
     => "myDir/file.txt"

   absolutePathToRelativeHome "/home/myUser/myDir/file.txt" {} => "myDir/file.txt"
   ```
  */
  absolutePathToRelativeHome =
    # (Path) The absolute path that should be transformed to a relative one
    path: {
      # (String) Username that will be used to parse the homedir. Default: module level user if provided, otherwise "root"
      _user,
      # (Path) In case of a nontraditional /home structure, you can provide the full homedir path. Default: null
      home ? null,
      # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attrset enabled parsing homedir directly via the usersSystem module. Default: null
      cfg ? null,
    }:
      strings.removePrefix
      ((
          if home != null
          then home
          else getUserHomeDir {inherit _user cfg;}
        )
        + "/")
      path;
}
