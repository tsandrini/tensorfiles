# --- modules/default.nix
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
    # misc --
    misc_gtk = import ./misc/gtk.nix;
    misc_nix = import ./misc/nix.nix;
    misc_xdg = import ./misc/xdg.nix;

    # -- profiles --
    profiles_base = import ./profiles/base.nix;
    profiles_graphical-hyprland = import ./profiles/graphical-hyprland.nix;
    profiles_graphical-xmonad = import ./profiles/graphical-xmonad.nix;
    profiles_headless = import ./profiles/headless.nix;
    profiles_minimal = import ./profiles/minimal.nix;

    # -- programs --
    programs_direnv = import ./programs/direnv.nix;
    programs_dmenu = import ./programs/dmenu.nix;
    programs_git = import ./programs/git.nix;
    programs_newsboat = import ./programs/newsboat.nix;
    programs_pywal = import ./programs/pywal.nix;
    ## -- browsers --
    programs_browsers_firefox = import ./programs/browsers/firefox;
    ## -- editors --
    programs_editors_neovim = import ./programs/editors/neovim.nix;
    ## -- file-managers --
    programs_file-managers_lf = import ./programs/file-managers/lf;
    ## -- shells --
    programs_shells_zsh = import ./programs/shells/zsh;
    ## -- terminals --
    programs_terminals_alacritty = import ./programs/terminals/alacritty.nix;
    programs_terminals_kitty = import ./programs/terminals/kitty.nix;
    ## -- wayland --
    programs_wayland_waybar = import ./programs/wayland/waybar;
    programs_wayland_anyrun = import ./programs/wayland/anyrun.nix;
    programs_wayland_ags = import ./programs/wayland/ags.nix;

    # -- security --
    security_agenix = import ./security/agenix.nix;

    # -- services --
    services_dunst = import ./services/dunst.nix;
    services_pywalfox-native = import ./services/pywalfox-native.nix;
    ## -- networking --
    services_networking_networkmanager = import ./services/networking/networkmanager.nix;
    services_networking_openssh = import ./services/networking/openssh.nix;
    ## -- x11 --
    services_x11_picom = import ./services/x11/picom.nix;
    services_x11_redshift = import ./services/x11/redshift.nix;
    ### -- window-managers --
    services_x11_window-managers_xmonad = import ./services/x11/window-managers/xmonad;
    ## -- wayland --
    ### -- window-managers --
    services_wayland_window-managers_hyprland = import ./services/wayland/window-managers/hyprland.nix;

    # -- system --
    system_persistence = import ./system/persistence.nix;
    system_users = import ./system/users.nix;

    # -- tasks --
    tasks_nix-garbage-collect = import ./tasks/nix-garbage-collect.nix;
    tasks_system-autoupgrade = import ./tasks/system-autoupgrade.nix;
  };
}