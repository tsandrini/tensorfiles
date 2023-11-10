# --- modules/profiles/headless.nix
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
{ config, lib, pkgs, inputs, user ? "root", projectPath
, secretsPath ? (projectPath + "/secrets"), ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.headless;
  _ = mkOverrideAtProfileLevel;

  usersRootCfg = config.tensorfiles.system.users.home.settings."root";
  enableMainUser = user != "root";

  usersMainCfg = if enableMainUser then
    config.tensorfiles.system.users.home.settings."${user}"
  else
    { };
in {
  options.tensorfiles.profiles.headless = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the headless system profile.

        **Headless layer** builds on top of the minimal layer and adds other
        server-like functionalty like simple shells, basic networking for remote
        access and simple editors.
      '');
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      tensorfiles = {
        profiles.minimal.enable = _ true;

        programs.editors.neovim.enable = _ true;
        programs.git.enable = _ true;
        programs.shells.zsh.enable = _ true;
        security.agenix.enable = _ true;

        services.networking.networkmanager.enable = _ true;
        services.networking.openssh.enable = _ true;

        misc.xdg.home.settings = {
          "root" = { };
          "${if enableMainUser then user else "_"}" = mkIf enableMainUser { };
        };

        system.users.home.settings = {
          "root" = {
            isSudoer = _ false;
            agenixPassword.enable = _ (pathExists (secretsPath
              + "/${usersRootCfg.agenixPassword.passwordSecretsPath}.age"));
          };
          "${if enableMainUser then user else "_"}" = mkIf enableMainUser {
            isSudoer = _ true;
            email = _ "tomas.sandrini@seznam.cz"; # TODO uhhh dunno, do smth
            agenixPassword.enable = _ (pathExists (secretsPath
              + "/${usersMainCfg.agenixPassword.passwordSecretsPath}.age"));
          };
        };

      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
