# --- profiles/home-manager.nix
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
{ config, pkgs, lib, inputs, user, ... }:
let _ = lib.mkOverride 500;
in {
  home-manager.useGlobalPkgs = _ true;
  home-manager.useUserPackages = _ true;

  users.mutableUsers = _ false;

  users.users.${user} = {
    isNormalUser = _ true;
    extraGroups =
      [ "wheel" "video" "audio" "camera" "networkmanager" "lightdm" ];
    home = _ "/home/${user}";
    description = _
      "life is full of pain and suffering but atleast I have a functioning computer hehe";
    passwordFile =
      _ config.age.secrets."common/passwords/users/${user}_default".path;
  };

  users.users.root = {
    passwordFile =
      _ config.age.secrets."common/passwords/users/root_default".path;
  };

  home-manager.users.${user} = {
    home = {
      username = _ "${user}";
      homeDirectory = _ "/home/${user}";
      stateVersion = "23.05";
    };

    fonts.fontconfig.enable = _ true;
  };

  age.secrets."common/passwords/users/${user}_default".file =
    ../secrets/common/passwords/users/${user}_default.age;
  age.secrets."common/passwords/users/root_default".file =
    ../secrets/common/passwords/users/root_default.age;

  environment.persistence = lib.mkIf (config.environment ? persistence) {
    "/persist".users.${user} = {
      directories = [
        "Downloads"
        "FiberBundle"
        "org"
        "ProjectBundle"
        "ZoteroStorage"
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
