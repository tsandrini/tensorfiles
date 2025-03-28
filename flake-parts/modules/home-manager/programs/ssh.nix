# --- flake-parts/modules/home-manager/programs/ssh.nix
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
{
  localFlake,
  secretsPath,
  pubkeys,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    attrByPath
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.ssh;
  _ = mkOverrideAtHmModuleLevel;

  sshKeyCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix") && cfg.sshKey.enable;
in
{
  options.tensorfiles.hm.programs.ssh = {
    enable = mkEnableOption ''
      TODO
    '';

    sshKey = {
      enable = mkEnableOption ''
        TODO
      '';

      privateKeySecretsPath = mkOption {
        type = types.str;
        default = "hosts/${hostName}/users/$user/private_key";
        description = ''
          TODO
        '';
      };

      privateKeyHomePath = mkOption {
        type = types.str;
        default = ".ssh/id_ed25519";
        description = ''
          TODO
        '';
      };

      publicKeyHomePath = mkOption {
        type = types.str;
        default = ".ssh/id_ed25519.pub";
        description = ''
          TODO
        '';
      };

      publicKeyRaw = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          TODO
        '';
      };

      publicKeySecretsAttrsetKey = mkOption {
        type = types.str;
        default = "hosts.${hostName}.users.$user.sshKey";
        description = ''
          TODO
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.ssh = {
        enable = _ true;
      };

      programs.keychain = {
        enable = _ true;
        # NOTE enabled by default so probably unnecessary
        # enableBashIntegration = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.bash");
        # enableZshIntegration = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.zsh");
        # enableFishIntegration = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.fish");
        # enableNushellIntegration = _ (
        #   isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.nushell"
        # );
        agents = [ "ssh" ];
        extraFlags = [
          "--nogui"
          "--quiet"
        ];
        keys = [ "id_ed25519" ];
      };

      services.ssh-agent.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
    (mkIf sshKeyCheck {
      age.secrets."${cfg.sshKey.privateKeySecretsPath}" = {
        file = _ (secretsPath + "/${cfg.sshKey.privateKeySecretsPath}.age");
        # mode = _ "600";
        # owner = _ config.home.username; # NOTE not available in HM module
      };

      home.file = with cfg.sshKey; {
        "${privateKeyHomePath}".source = _ (
          config.lib.file.mkOutOfStoreSymlink config.age.secrets."${privateKeySecretsPath}".path
        );

        "${publicKeyHomePath}".text =
          let
            key =
              if publicKeyRaw != null then
                publicKeyRaw
              else
                (attrByPath (replaceStrings [ "$user" ] [ config.home.username ] (
                  splitString "." publicKeySecretsAttrsetKey
                )) "" pubkeys);
          in
          _ key;
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
