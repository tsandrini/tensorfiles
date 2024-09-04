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
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (inputs.flake-parts.lib) importApply;
  localFlake = self;
in
{
  options.flake.homeModules = mkOption {
    type = types.lazyAttrsOf types.unspecified;
    default = { };
  };

  config.flake.homeModules = {
    # -- hardware --
    # TODO nixGL requires --impure
    # hardware_nixGL = importApply ./hardware/nixGL.nix { inherit localFlake inputs; };

    # -- misc --
    misc_gtk = importApply ./misc/gtk.nix { inherit localFlake; };
    misc_xdg = importApply ./misc/xdg.nix { inherit localFlake; };

    # -- profiles --
    profiles_accounts_tsandrini = importApply ./profiles/accounts/tsandrini.nix {
      inherit localFlake;
      inherit (config.agenix) secretsPath;
    };
    profiles_base = importApply ./profiles/base.nix { inherit localFlake; };
    profiles_graphical-plasma = importApply ./profiles/graphical-plasma { inherit localFlake inputs; };
    profiles_graphical-xmonad = importApply ./profiles/graphical-xmonad.nix { inherit localFlake; };
    profiles_headless = importApply ./profiles/headless.nix { inherit localFlake; };
    profiles_minimal = importApply ./profiles/minimal.nix { inherit localFlake; };

    # -- programs --
    programs_browsers_firefox = importApply ./programs/browsers/firefox { inherit localFlake inputs; };
    programs_btop = importApply ./programs/btop.nix { inherit localFlake; };
    programs_tmux = importApply ./programs/tmux.nix { inherit localFlake; };
    programs_direnv = importApply ./programs/direnv.nix { inherit localFlake; };
    programs_dmenu = importApply ./programs/dmenu.nix { inherit localFlake; };
    programs_editors_emacs-doom = importApply ./programs/editors/emacs-doom.nix {
      inherit localFlake inputs;
    };
    programs_editors_neovim = importApply ./programs/editors/neovim.nix { inherit localFlake; };
    programs_file-managers_lf = importApply ./programs/file-managers/lf { inherit localFlake; };
    programs_file-managers_yazi = importApply ./programs/file-managers/yazi.nix { inherit localFlake; };
    programs_git = importApply ./programs/git.nix { inherit localFlake; };
    programs_gpg = importApply ./programs/gpg.nix { inherit localFlake; };
    programs_newsboat = importApply ./programs/newsboat.nix { inherit localFlake; };
    programs_pywal = importApply ./programs/pywal.nix { inherit localFlake; };
    programs_shadow-nix = importApply ./programs/shadow-nix.nix { inherit localFlake inputs; };
    programs_shells_zsh = importApply ./programs/shells/zsh { inherit localFlake; };
    programs_shells_fish = importApply ./programs/shells/fish.nix { inherit localFlake; };
    # programs_spicetify = importApply ./programs/spicetify.nix { inherit localFlake inputs; };
    programs_ssh = importApply ./programs/ssh.nix {
      inherit (config.agenix) secretsPath pubkeys;
      inherit localFlake;
    };
    programs_terminals_alacritty = importApply ./programs/terminals/alacritty.nix {
      inherit localFlake;
    };
    programs_terminals_kitty = importApply ./programs/terminals/kitty.nix { inherit localFlake; };
    programs_terminals_wezterm = importApply ./programs/terminals/wezterm.nix {
      inherit localFlake inputs;
    };
    programs_thunderbird = importApply ./programs/thunderbird.nix { inherit localFlake; };

    # -- security --

    # -- services --
    services_activitywatch = importApply ./services/activitywatch.nix { inherit localFlake; };
    services_dunst = importApply ./services/dunst.nix { inherit localFlake; };
    services_keepassxc = importApply ./services/keepassxc.nix { inherit localFlake; };
    services_pywalfox-native = importApply ./services/pywalfox-native.nix { inherit localFlake; };
    services_x11_picom = importApply ./services/x11/picom.nix { inherit localFlake; };
    services_x11_redshift = importApply ./services/x11/redshift.nix { inherit localFlake; };
    services_x11_window-managers_xmonad = importApply ./services/x11/window-managers/xmonad {
      inherit localFlake;
    };

    # -- system --
    system_impermanence = importApply ./system/impermanence.nix { inherit localFlake inputs; };

    # -- tasks --
  };
}
