# --- parts/modules/nixos/services/networking.ssh.nix
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
  config,
  lib,
  ...
}:
with builtins;
with lib; let
  cfg = config.tensorfiles.services.networking.ssh;
  _ = mkOverride 500;
in {
  options.tensorfiles.services.networking.ssh = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles everything related to ssh,
      that is remote access, messagess, ssh-agents and ssh-keys with the
      openssh backend.
    '');

    genHostKey = {
      enable = mkEnableOption (mdDoc ''
        Enables autogenerating per-host based keys. Apart from certain additional
        checks this works mostly as a passthrough to
        `openssh.authorizedKeys.keys`, for more info refer to the documentation
        of said option.
      '');

      hostKey = mkOption {
        type = attrs;
        default = {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        };
        description = mdDoc ''
          TODO
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.ssh = {
        startAgent = _ true;
        extraConfig = mkBefore ''
          # a private key that is used during authentication will be added to ssh-agent if it is running
          AddKeysToAgent yes
        '';
      };
      services.openssh = {
        enable = _ true;
        banner = mkBefore ''
          =====================================================================
          Welcome, you should note that this host is completely
          built/rebuilt/managed using the nix ecosystem and any manual changes
          will most probably be lost. If you are unsure about what you are
          doing, please refer to the tensorfiles documentation.

          Thank you and happy computing.
          =====================================================================
        '';
        settings = {
          PermitRootLogin = _ "no";
          PasswordAuthentication = _ false;
          StrictModes = _ true;
          KbdInteractiveAuthentication = _ false;
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.genHostKey.enable {
      services.openssh.hostKeys = [cfg.genHostKey.hostKey];
    })
    # |----------------------------------------------------------------------| #
  ]);
}
