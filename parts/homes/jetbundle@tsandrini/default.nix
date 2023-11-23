# --- parts/homes/jetbundle@tsandrini/default.nix
{config, ...}: {
  config = {
    # misc
    tensorfiles.hm.misc.xdg.enable = true;
    tensorfiles.hm.misc.gtk.enable = true;
    # hardware
    tensorfiles.hm.hardware.nixGL.enable = true;
    # programs
    tensorfiles.hm.programs.direnv.enable = true;
    tensorfiles.hm.programs.dmenu.enable = true;
    tensorfiles.hm.programs.editors.neovim.enable = true;
    tensorfiles.hm.programs.newsboat.enable = true;
    tensorfiles.hm.programs.pywal.enable = true;
    tensorfiles.hm.programs.shells.zsh.enable = true;
    tensorfiles.hm.programs.terminals.kitty.enable = true;
    # services
    tensorfiles.hm.services.dunst.enable = true;
    tensorfiles.hm.services.x11.picom.enable = true;
    tensorfiles.hm.services.x11.redshift.enable = true;

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.stateVersion = "23.05";
    home.sessionVariables = {
      BROWSER = "firefox";
      TERMINAL = "kitty";
    };

    programs.home-manager.enable = true;
  };
}
