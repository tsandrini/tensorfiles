# --- flake-parts/modules/home-manager/programs/handoff.nix
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
{ localFlake, secretsPath }:
{
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    literalExpression
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.handoff;
  _ = mkOverrideAtHmModuleLevel;

  agenixCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix")
    && cfg.cryptPasswordSecretsPath != null;
in
{
  options.tensorfiles.hm.programs.handoff = {
    enable = mkEnableOption ''
      Installs `handoff`, which carries dirty git working trees between
      machines through an encrypted rclone relay (`push` before leaving,
      `pull` on arrival). See `flake-parts/pkgs/handoff/README.md`.

      The config names repositories and is therefore private: either keep
      `~/.config/handoff/config.toml` by hand or point `configFile` at an
      agenix-decrypted file. The relay encryption password is an agenix
      secret shared by every host that syncs (`cryptPasswordSecretsPath`);
      reference its decrypted path from the config's `crypt.password_file`.
    '';

    package = mkOption {
      type = types.package;
      default = localFlake.packages.${system}.handoff;
      defaultText = literalExpression "tensorfiles.packages.\${system}.handoff";
      description = "The `handoff` package, see `flake-parts/pkgs/handoff`.";
    };

    configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression "config.age.secrets.handoff-config.path";
      description = ''
        Config file exported as `HANDOFF_CONFIG`. `null` leaves the lookup
        to the tool (`--config`, then `$XDG_CONFIG_HOME/handoff/config.toml`).
      '';
    };

    cryptPasswordSecretsPath = mkOption {
      type = types.nullOr types.str;
      default = "common/handoff-crypt-password";
      description = ''
        Path (relative to the agenix secrets directory, without the `.age`
        suffix) of the relay encryption password, decrypted into the user's
        agenix directory when agenix is enabled. `null` skips the secret.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [ cfg.package ];
    }
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.configFile != null) {
      home.sessionVariables.HANDOFF_CONFIG = _ cfg.configFile;
    })
    # |----------------------------------------------------------------------| #
    (mkIf agenixCheck {
      age.secrets."${cfg.cryptPasswordSecretsPath}" = {
        file = _ (secretsPath + "/${cfg.cryptPasswordSecretsPath}.age");
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
