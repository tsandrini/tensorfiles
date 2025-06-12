# --- parts/modules/nixos/default.nix
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
  config,
  inputs,
  self,
  ...
}:
let
  inherit (inputs.flake-parts.lib) importApply;
  inherit (config.agenix) secretsPath;
  localFlake = self;
in
{
  flake.nixosModules = {
    # -- misc --
    misc_nix = importApply ./misc/nix.nix { inherit inputs localFlake; };

    # -- profiles --
    profiles_base = importApply ./profiles/base.nix { inherit localFlake; };
    profiles_packages-base = importApply ./profiles/packages-base.nix { inherit localFlake; };
    profiles_packages-extra = importApply ./profiles/packages-extra.nix { inherit localFlake inputs; };
    profiles_graphical-plasma5 = importApply ./profiles/graphical-plasma5.nix {
      inherit localFlake inputs;
    };
    profiles_graphical-plasma6 = importApply ./profiles/graphical-plasma6.nix {
      inherit localFlake inputs;
    };
    profiles_graphical-startx-home-manager = importApply ./profiles/graphical-startx-home-manager.nix {
      inherit localFlake;
    };
    profiles_headless = importApply ./profiles/headless.nix { inherit localFlake secretsPath; };
    profiles_minimal = importApply ./profiles/minimal.nix { inherit localFlake; };

    # -- programs --
    programs_shadow-nix = importApply ./programs/shadow-nix.nix { inherit localFlake inputs; };
    programs_nh = importApply ./programs/nh.nix { inherit localFlake; };

    # -- security --

    # -- services --
    services_networking_networkmanager = importApply ./services/networking/networkmanager.nix {
      inherit localFlake;
    };
    services_networking_ssh = importApply ./services/networking/ssh.nix { inherit localFlake; };
    services_x11_desktop-managers_startx-home-manager =
      importApply ./services/x11/desktop-managers/startx-home-manager.nix
        { inherit localFlake; };
    services_mailserver = importApply ./services/mailserver.nix {
      inherit localFlake inputs;
      inherit (config.agenix) secretsPath;
    };
    services_monit = importApply ./services/monit.nix {
      inherit localFlake;
    };

    # -- system --
    system_impermanence = importApply ./system/impermanence.nix { inherit localFlake inputs; };
    system_users = importApply ./system/users.nix {
      inherit localFlake;
      inherit (config.agenix) secretsPath pubkeys;
    };

    # -- tasks --
    tasks_nix-garbage-collect = importApply ./tasks/nix-garbage-collect.nix { inherit localFlake; };
    tasks_system-autoupgrade = importApply ./tasks/system-autoupgrade.nix { inherit localFlake; };
  };
}
