# --- flake-parts/lib/options.nix
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
{ lib }:
with lib;
with lib.types;
with builtins;
{

  /*
    Creates an enableOption targeted for the management of the impermanence
    system.

    *Type*: `Option`
  */
  mkImpermanenceEnableOption =
    mkEnableOption ''
      Whether to autoappend files/folders to the persistence system.
      For more info on the persistence system refer to the system.persistence
      NixOS module documentation.

      Note that this will get executed only if

      1. persistence.enable = true;

      2. tensorfiles.system.persistence module is loaded

      3. tensorfiles.system.persistence.enable = true;
    ''
    // {
      default = true;
    };

  /*
    Creates an enableOption targeted for the integration with the pywal
    colorscheme generator.

    *Type*: `Option`
  */
  mkPywalEnableOption =
    mkEnableOption ''
      Whether to enable the integration with the pywal colorscheme generator
      program. The integration may range from just some color parsing/loading to
      sometimes full on detailed plugins depending on the context.

      Note that the code will get execute only if

      1. pywal.enable = true;

      2. tensorfiles.programs.pywal module is loaded

      3. tensorfiles.programs.pywal.enable = true;
    ''
    // {
      default = true;
    };

  /*
    Creates an enableOption targeted for the management of the agenix
    security system.

    *Type*: `Option`
  */
  mkAgenixEnableOption =
    mkEnableOption ''
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
    ''
    // {
      default = true;
    };

  /*
    Submodule option used for handling multiple-user configuration setups.
    After the definition you can iterate over the users in the following manner

    Example:
    ```
    users.users = genAttrs (attrNames cfg.usersSettings) (_user: let
      userCfg = cfg.usersSettings."${_user}";
    in {
      myOption = userCfg.myOption;
      myOtherOption = 2 * userCfg.myOtherOption;
    };
    ```
  */
  mkUsersSettingsOption =
    # (String -> AttrSet a) Function that, given a username, yields all of the users related options for that given user
    generatorFunction:
    mkOption {
      type = attrsOf (
        submodule (
          { name, ... }:
          {
            options = generatorFunction name;
          }
        )
      );
      default = { };
      example = {
        "root" = {
          myOption = false;
          otherOption.name = "test1";
        };
        "myUser" = {
          myOption = true;
          otherOption.name = "test2";
        };
        # just initialize the defaults
        "myOtherUser" = { };
      };
      description = ''
        Multiuser users configuration option submodule.
        Enables doing module level configurations via simple attrsets.
      '';
    };
}
