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
{
  lib,
  user ? "root",
  ...
}:
with lib;
with builtins; rec {
  /*
  Check whether the persistence system is enabled, that is whether

  1. The `tensorfiles.system.persistence` module is imported

  2. It is also enabled

  *Type*: `isPersistenceEnabled :: AttrSet -> Bool`
  */
  isPersistenceEnabled =
    # (AttrSet) An AttrSet with the already parsed NixOS config
    cfg:
      (cfg ? tensorfiles.system.persistence)
      && (cfg.tensorfiles.system.persistence.enable);

  /*
  Check whether the agenix system is enabled, that is whether

  1. The `tensorfiles.security.agenix` moduls is imported

  2. It is also enabled

  *Type*: `isAgenixEnabled :: AttrSet -> Bool`
  */
  isAgenixEnabled =
    # (AttrSet) An AttrSet with the already parsed NixOS config
    cfg:
      (cfg ? tensorfiles.security.agenix)
      && (cfg.tensorfiles.security.agenix.enable);

  /*
  Check whether the agenix system is enabled, that is whether

  1. The `tensorfiles.system.users` module is imported

  2. It is also enabled

  *Type*: `isUsersSystemEnabled :: AttrSet -> Bool`
  */
  isUsersSystemEnabled =
    # (AttrSet) An AttrSet with the already parsed NixOS config
    cfg:
      (cfg ? tensorfiles.system.users) && (cfg.tensorfiles.system.users.enable);

  /*
  Check whether the pywal theme system module is enabled, that is whether

  1. The `tensorfiles.programs.pywal` module is imported

  2. It is also enabled

  *Type*: `isPywalEnabled:: AttrSet -> Bool`
  */
  isPywalEnabled =
    # (AttrSet) An AttrSet with the already parsed NixOS config
    cfg:
      (cfg ? tensorfiles.programs.pywal)
      && (cfg.tensorfiles.programs.pywal.enable);

  /*
  Transforms an absolute path to a one relative to the given user home
  directory. It basically functions as a case handler for
  `lib.strings.removePreffix` to handle a variety of different cases.

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
      _user ? user,
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

  /*
  A generic function for parsing the user home directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the homeDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, it will check whether home-manager is enabled, loaded and if the
     user is well defined inside, in that case it will return the
     home.homeDirectory variable.

  3. If not, it will check whether the user is well defined in the users.users
     attrset and if yes, it will return the home variable.

  4. If not, it will manually return either the usual "/home/$user" or "/root"
     depending on the context

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserHomeDir { _user = "myUser"; }
    => "/home/myUser"

  getUserHomeDir { _user = "root"; }
    => "/root"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".homeDir = "/var/mySecretDir";
  getUserHomeDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir"

  tensorfiles.system.users.enable = false;
  home-manager.users."myUser".home.homeDirectory = null;
  users.users."myUser".home = "/var/myOtherSecretDir";
  getUserHomeDir { _user = "myUser"; cfg = config; }
    =>  "/var/myOtherSecretDir"
  ```
  */
  getUserHomeDir = {
    # (String) Target user whose home directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the home directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }: let
    fallbackValue =
      if _user != "root"
      then "/home/${_user}"
      else "/root";
  in
    if (cfg != null)
    then
      (
        if
          ((isUsersSystemEnabled cfg)
            && (hasAttr _user cfg.tensorfiles.system.users.home.settings)
            && (cfg.tensorfiles.system.users.home.settings.${_user}.homeDir
              != null))
        then cfg.tensorfiles.system.users.home.settings.${_user}.homeDir
        else if
          ((hasAttr "home-manager" cfg)
            && (hasAttr _user cfg.home-manager.users)
            && (cfg.home-manager.users.${_user}.home.homeDirectory != null))
        then cfg.home-manager.${_user}.home.homeDirectory
        else if
          ((hasAttr _user cfg.users.users)
            && (cfg.users.users.${_user}.home != null))
        then cfg.users.users.${_user}.home
        else fallbackValue
      )
    else fallbackValue;

  /*
  A generic function for parsing the user config directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the configDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, the home directory will be dynamically retrieved using the
     `getUserHomeDir` function and `.config` will simply be appended to it
     and returned.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserConfigDir { _user = "myUser"; }
    => "/home/myUser/.config"

  getUserConfigDir { _user = "root"; }
    => "/root/.config"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".configDir = "/var/mySecretDir/configuration";
  getUserConfigDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir/configuration"
  ```
  */
  getUserConfigDir = {
    # (String) Target user whose config directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the config directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.configDir
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.configDir
    else let
      homeDir = getUserHomeDir {inherit _user cfg;};
    in "${homeDir}/.config";

  /*
  A generic function for parsing the user cache directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the cacheDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, the home directory will be dynamically retrieved using the
     `getUserHomeDir` function and `.cache` will simply be appended to it
     and returned.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserCacheDir { _user = "myUser"; }
    => "/home/myUser/.cache"

  getUserCacheDir { _user = "root"; }
    => "/root/.cache"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".cacheDir = "/var/mySecretDir/cache";
  getUserCacheDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir/cache"
  ```
  */
  getUserCacheDir = {
    # (String) Target user whose cache directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the cache directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.cacheDir
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.cacheDir
    else let
      homeDir = getUserHomeDir {inherit _user cfg;};
    in "${homeDir}/.cache";

  /*
  A generic function for parsing the user app data directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the appDataDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, the home directory will be dynamically retrieved using the
     `getUserHomeDir` function and `.local/share` will simply be appended to it
     and returned.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserAppDataDir { _user = "myUser"; }
    => "/home/myUser/.local/share"

  getUserAppDataDir { _user = "root"; }
    => "/root/.local/share"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".appDataDir = "/var/mySecretDir/appData";
  getUserAppDataDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir/appData"
  ```
  */
  getUserAppDataDir = {
    # (String) Target user whose app data directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the app data directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.appDataDir
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.appDataDir
    else let
      homeDir = getUserHomeDir {inherit _user cfg;};
    in "${homeDir}/.local/share";

  /*
  A generic function for parsing the user app state directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the appStateDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, the home directory will be dynamically retrieved using the
     `getUserHomeDir` function and `.local/state` will simply be appended to it
     and returned.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserAppStateDir { _user = "myUser"; }
    => "/home/myUser/.local/state"

  getUserAppStateDir { _user = "root"; }
    => "/root/.local/state"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".appStateDir = "/var/mySecretDir/appState";
  getUserAppStateDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir/appState"
  */
  getUserAppStateDir = {
    # (String) Target user whose app state directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the app state directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.appStateDir
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.appStateDir
    else let
      homeDir = getUserHomeDir {inherit _user cfg;};
    in "${homeDir}/.local/state";

  /*
  A generic function for parsing the user Downloads directory. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the downloadsDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, the home directory will be dynamically retrieved using the
     `getUserHomeDir` function and `Downloads` will simply be appended to it
     and returned.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> Path`

  Example:
  ```nix title="Example" linenums="1"
  getUserDownloadsDir { _user = "myUser"; }
    => "/home/myUser/Downloads"

  getUserDownloadsDir { _user = "root"; }
    => "/root/Downloads"

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".downloadsDir = "/var/mySecretDir/downloaded_stuff";
  getUserHomeDir { _user = "myUser"; cfg = config; }
    =>  "/var/mySecretDir/downloaded_stuff"
  ```
  */
  getUserDownloadsDir = {
    # (String) Target user whose Downloads directory should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the Downloads directory dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.downloadsDir
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.downloadsDir
    else let
      homeDir = getUserHomeDir {inherit _user cfg;};
    in "${homeDir}/Downloads";

  /*
  A generic function for parsing the user email. The parsing will be
  attempted in the following order:

  1. In case that the users system is enabled, the value will be parsed
     from the appStateDir home.settings option of the users module (if the user
     is entry is well defined in the home.settings attrset).

  2. If not, it will return `null`, since that's for now the only available
     option.

  This method is designed to be an abstraction between different
  modules/systems that provide this kind of functionality. It enables writing
  extensible nix expressions instead of relying on any specific module that
  the end user might not have enabled or might even remove in the future.

  *Type*: `{ _user :: String; cfg :: AttrSet } -> (String | null)`

  Example:
  ```nix title="Example" linenums="1"
  getUserEmail { _user = "myUser"; }
    => null

  tensorfiles.system.users.enable = true;
  tensorfiles.system.users.home.enable = true;
  tensorfiles.system.users.home."myUser".email = "myUser@email.com";
  getUserEmail { _user = "myUser"; cfg = config; }
    => "myUser@email.com"
  ```
  */
  getUserEmail = {
    # (String) Target user whose email should be parsed. Default: user passed during lib init
    _user ? user,
    # (AttrSet) An AttrSet with the already parsed NixOS config. Passing this attribute enables parsing the email dynamically from the configuration itself rather than statically.
    cfg ? null,
  }:
    if
      ((cfg != null)
        && (isUsersSystemEnabled cfg)
        && (cfg.tensorfiles.system.users.home.settings.${_user}.email
          != null))
    then cfg.tensorfiles.system.users.home.settings.${_user}.email
    else null;
}
