# --- parts/homes/jetbundle@tsandrini/default.nix
{config, ...}: {
  config = {
    tensorfiles.hm.programs.editors.neovim.enable = true;

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.stateVersion = "23.05";

    programs.home-manager.enable = true;
  };
}
