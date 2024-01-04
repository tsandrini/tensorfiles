# --- parts/modules/nixos/default.nix
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
_: {
  flake.nixosModules = {
    # -- misc --
    misc_nix = import ./misc/nix.nix;

    # -- profiles --
    profiles_base = import ./profiles/base.nix;
    profiles_minimal = import ./profiles/minimal.nix;
    profiles_headless = import ./profiles/headless.nix;
    profiles_graphical-startx-home-manager = import ./profiles/graphical-startx-home-manager.nix;

    # -- programs --
    programs_shadow-nix = import ./programs/shadow-nix.nix;

    # -- security --

    # -- services --
    ## -- networking --
    services_networking_networkmanager = import ./services/networking/networkmanager.nix;
    services_networking_ssh = import ./services/networking/ssh.nix;
    ### -- window-managers --
    services_x11_desktop-managers_startx-home-manager = import ./services/x11/desktop-managers/startx-home-manager.nix;

    # -- system --
    system_impermanence = import ./system/impermanence.nix;
    system_users = import ./system/users.nix;

    # -- tasks --
    tasks_nix-garbage-collect = import ./tasks/nix-garbage-collect.nix;
    tasks_system-autoupgrade = import ./tasks/system-autoupgrade.nix;
  };
}
