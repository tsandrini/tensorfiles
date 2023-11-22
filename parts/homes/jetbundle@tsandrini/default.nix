# --- parts/homes/jetbundle@tsandrini/default.nix
{config, ...}: {
  config = {
    tensorfiles.hm.programs.editors.neovim.enable = true;
    tensorfiles.hm.programs.shells.zsh.enable = true;
    tensorfiles.hm.programs.pywal.enable = true;
    tensorfiles.hm.misc.xdg.enable = true;

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.stateVersion = "23.05";

    programs.home-manager.enable = true;
  };
}
