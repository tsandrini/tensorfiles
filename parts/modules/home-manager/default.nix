# --- modules/home-manager/default.nix
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

    # -- programs --
    programs_direnv = import ./programs/direnv.nix;
    programs_ssh = import ./programs/ssh.nix;
    programs_dmenu = import ./programs/dmenu.nix;
    programs_git = import ./programs/git.nix;
    programs_newsboat = import ./programs/newsboat.nix;
    programs_pywal = import ./programs/pywal.nix;
    ## -- editors --
    programs_editors_neovim = import ./programs/editors/neovim.nix;
    programs_editors_emacs-doom = import ./programs/editors/emacs-doom.nix;
    ## -- shells --
    programs_shells_zsh = import ./programs/shells/zsh;
    ## -- terminals --
    programs_terminals_kitty = import ./programs/terminals/kitty.nix;
    programs_terminals_alacritty = import ./programs/terminals/alacritty.nix;
    ## -- browsers --
    programs_browsers_firefox = import ./programs/browsers/firefox;

    # -- security --
    security_agenix = import ./security/agenix.nix;

    # -- services --
    services_dunst = import ./services/dunst.nix;
    services_pywalfox-native = import ./services/pywalfox-native.nix;
    ## -- x11 --
    services_x11_picom = import ./services/x11/picom.nix;
    services_x11_redshift = import ./services/x11/redshift.nix;

    # -- system --

    # -- tasks --
  };
}
