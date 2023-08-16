# --- lib/options.nix
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
{ lib, user ? "root", ... }:
with lib;
with lib.types;
with builtins; rec {

  /* Creates an enableOption (ie `mkEnableOption`), however, already
     preenabled.

     *Type*: `String -> Option`
  */
  mkAlreadyEnabledOption = description:
    (mkEnableOption description) // {
      default = true;
    };

  /* Creates an already enabled module enableOption with

     *Type*: `Option`
  */
  mkPersistenceEnableOption = mkEnableOption (mdDoc ''
    Whether to autoappend files/folders to the persistence system.
    For more info on the persistence system refer to the system.persistence
    NixOS module documentation.

    Note that this will get executed only if

    1. persistence.enable = true;

    2. tensorfiles.system.persistence module is loaded

    3. tensorfiles.system.persistence.enable = true;
  '') // {
    default = true;
  };

  mkAgenixEnableOption = mkEnableOption (mdDoc ''
    Whether to enable the agenix ecosystem for handling secrets, which includes

    a. passwords
    b. keys
    c. certificates

    There is a preferred way to organize secrets (see example at
    github:tsandrini/tensorfiles), however, most modules will accept a path
    override if you wish to do so. For this you should look into the `agenix`
    related options of the appropriate modules. If this is not okay for you, you
    should set the password manually yourself instead.

    Note that this will get executed only if

    1. agenix = true;
    2. tensorfiles.security.agenix module is loaded
    3. tensorfiles.security.agenix.enable = true;
  '') // {
    default = true;
  };

  mkHomeEnableOption = mkOption {
    type = bool;
    default = true;
    example = false;
    description = mdDoc ''
      Enable multi-user configuration via home-manager.

      The configuration is then done via the settings option with the toplevel
      attribute being the name of the user, for example:

      ```
      home.enable = true;
      home.settings."root" = {
        myOption = false;
        otherOption.name = "test1";
        # etc...
      };
      home.settings."myUser" = {
        myOption = true;
        otherOption.name = "test2";
        # etc...
      };
      ```
    '';
  };

  mkHomeSettingsOption = generatorFunction:
    mkOption {
      type = attrsOf
        (submodule ({ name, ... }: { options = (generatorFunction name); }));
      # Note: It's sufficient to just create the toplevel attribute and the
      # rest will be automatically populated with the default option values.
      default = { "${user}" = { }; };
      example = {
        "root" = {
          myOption = false;
          otherOption.name = "test1";
        };
        "myUser" = {
          myOption = true;
          otherOption.name = "test2";
        };
      };
      description = mdDoc ''
        The configuration is then done via the settings option with the toplevel
        attribute being the name of the user, for example:

        ```
        home.enable = true;
        home.settings."root" = {
          myOption = false;
          otherOption.name = "test1";
          # etc...
        };
        home.settings."myUser" = {
          myOption = true;
          otherOption.name = "test2";
          # etc...
        };
        ```
      '';
    };
}
