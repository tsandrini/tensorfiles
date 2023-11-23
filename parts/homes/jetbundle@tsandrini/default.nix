# --- parts/homes/jetbundle@tsandrini/default.nix
{config, ...}: {
  config = {
    tensorfiles.hm.programs.editors.neovim.enable = true;
    tensorfiles.hm.programs.shells.zsh.enable = true;
    tensorfiles.hm.programs.terminals.kitty.enable = true;
    tensorfiles.hm.programs.pywal.enable = true;
    tensorfiles.hm.programs.newsboat.enable = true;
    tensorfiles.hm.programs.direnv.enable = true;
    tensorfiles.hm.programs.dmenu.enable = true;
    tensorfiles.hm.misc.xdg.enable = true;
    tensorfiles.hm.hardware.nixGL.enable = true;

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.stateVersion = "23.05";

    programs.home-manager.enable = true;
  };
}
