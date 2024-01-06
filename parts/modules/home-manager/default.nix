# --- parts/modules/home-manager/default.nix
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
{lib, ...}: {
  options.flake.homeModules = lib.mkOption {
    type = with lib.types; lazyAttrsOf unspecified;
    default = {};
  };

  config.flake.homeModules = {
    # -- hardware --
    hardware_nixGL = import ./hardware/nixGL.nix;

    # -- misc --
    misc_xdg = import ./misc/xdg.nix;
    misc_gtk = import ./misc/gtk.nix;

    # -- profiles --
    profiles_base = import ./profiles/base.nix;
    profiles_minimal = import ./profiles/minimal.nix;
    profiles_headless = import ./profiles/headless.nix;
    profiles_graphical-xmonad = import ./profiles/graphical-xmonad.nix;
    # profiles_graphical-plasma6 = import ./profiles/graphical-plasma6.nix;

    # -- programs --
    programs_direnv = import ./programs/direnv.nix;
    programs_ssh = import ./programs/ssh.nix;
    programs_dmenu = import ./programs/dmenu.nix;
    programs_git = import ./programs/git.nix;
    programs_newsboat = import ./programs/newsboat.nix;
    programs_btop = import ./programs/btop.nix;
    programs_pywal = import ./programs/pywal.nix;
    programs_thunderbird = import ./programs/thunderbird.nix;
    programs_shadow-nix = import ./programs/shadow-nix.nix;
    ## -- editors --
    programs_editors_neovim = import ./programs/editors/neovim.nix;
    programs_editors_emacs-doom = import ./programs/editors/emacs-doom.nix;
    ## -- shells --
    programs_shells_zsh = import ./programs/shells/zsh;
    ## -- file-managers --
    programs_file-managers_lf = import ./programs/file-managers/lf;
    programs_file-managers_yazi = import ./programs/file-managers/yazi.nix;
    ## -- terminals --
    programs_terminals_kitty = import ./programs/terminals/kitty.nix;
    programs_terminals_alacritty = import ./programs/terminals/alacritty.nix;
    ## -- browsers --
    programs_browsers_firefox = import ./programs/browsers/firefox;

    # -- security --

    # -- services --
    services_keepassxc = import ./services/keepassxc.nix;
    services_dunst = import ./services/dunst.nix;
    services_pywalfox-native = import ./services/pywalfox-native.nix;
    ## -- x11 --
    services_x11_picom = import ./services/x11/picom.nix;
    services_x11_redshift = import ./services/x11/redshift.nix;
    services_x11_window-managers_xmonad = import ./services/x11/window-managers/xmonad;

    # -- system --
    system_impermanence = import ./system/impermanence.nix;

    # -- tasks --
  };
}
