# --- profiles/home-pywal/default.nix
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
{ config, pkgs, lib, inputs, user, ... }:
let
  _ = lib.mkOverride 500;
  cfg = config.home-manager.users.${user};
in {
  nixpkgs.config.permittedInsecurePackages = [ "python-2.7.18.6" ];

  home-manager.users.${user} = {
    home.packages = with pkgs; [ pywal python2 ];

    # Setup general templates
    home.file."${cfg.xdg.configHome}/wal/templates/Xresources".source =
      _ ./templates/Xresources;
    systemd.user.tmpfiles.rules = [
      "L ${cfg.home.homeDirectory}/.Xresources - - - - ${cfg.xdg.cacheHome}/wal/Xresources"
    ];

    programs.zsh.initExtra = lib.mkIf (cfg.programs.zsh.enable) ''
      # Import colorscheme from 'wal' asynchronously
      # &   # Run the process in the background.
      # ( ) # Hide shell job control messages.
      (cat ${cfg.xdg.cacheHome}/wal/sequences &)
    '';

    programs.neovim.plugins = with pkgs.vimPlugins;
      lib.mkIf (cfg.programs.neovim.enable) [{
        plugin = wal-vim;
        type = "lua";
        config = ''
          vim.cmd("colorscheme wal")
        '';
      }];
  };

  environment.persistence = lib.mkIf (config.environment ? persistence) {
    "/persist".users.${user} = {
      directories = [ ".cache/wal" ];
      files = [ ".fehbg" ];
    };
  };
}
