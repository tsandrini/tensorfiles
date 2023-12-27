# --- parts/homes/tsandrini@jetbundle/default.nix
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
  pkgs,
  ...
}: {
  config = {
    # misc
    tensorfiles.hm.misc.xdg.enable = true;
    tensorfiles.hm.misc.gtk.enable = true; # doesnt work unfortunately
    # hardware
    tensorfiles.hm.hardware.nixGL.enable = true;
    # programs
    tensorfiles.hm.programs.ssh.enable = true;
    tensorfiles.hm.programs.direnv.enable = true;
    tensorfiles.hm.programs.git.enable = true;
    tensorfiles.hm.programs.btop.enable = true;
    tensorfiles.hm.programs.dmenu.enable = true;
    tensorfiles.hm.programs.editors.neovim.enable = true;
    tensorfiles.hm.programs.editors.emacs-doom.enable = true;
    tensorfiles.hm.programs.newsboat.enable = true;
    tensorfiles.hm.programs.pywal.enable = true;
    tensorfiles.hm.programs.shells.zsh.enable = true;
    tensorfiles.hm.programs.terminals.kitty.enable = true;
    tensorfiles.hm.programs.file-managers.yazi.enable = true;
    tensorfiles.hm.programs.browsers.firefox.enable = true;
    # security
    tensorfiles.hm.security.agenix.enable = true;
    # services
    tensorfiles.hm.services.keepassxc.enable = true;
    tensorfiles.hm.services.dunst.enable = true;
    tensorfiles.hm.services.pywalfox-native.enable = true;
    tensorfiles.hm.services.x11.picom.enable = true;
    tensorfiles.hm.services.x11.redshift.enable = true;
    tensorfiles.hm.services.x11.window-managers.xmonad.enable = true;

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.stateVersion = "23.05";
    home.sessionVariables = {
      # Default programs
      BROWSER = "firefox";
      TERMINAL = "kitty";
      IDE = "emacs";
      EDITOR = "nvim";
      VISUAL = "nvim";
      # Directory structure
      DOWNLOADS_DIR = config.home.homeDirectory + "/Downloads";
      ORG_DIR = config.home.homeDirectory + "/OrgBundle";
      PROJECTS_DIR = config.home.homeDirectory + "/ProjectBundle";
      MISC_DATA_DIR = config.home.homeDirectory + "/FiberBundle";
      # Fallbacks
      DEFAULT_USERNAME = "tsandrini";
      DEFAULT_MAIL = "tomas.sandrini@seznam.cz";
    };

    home.packages = with pkgs; [
      # core
      openssh
      htop
      iotop
      jq
      wget
      unrar
      xclip
      dosfstools
      killall
      # chromium
      # other
      beeper
      armcord
      anki
      light
      calcurse
      flameshot
      mpv
      feh
      cbatticon
      mpv
      libnotify # TODO move libnotify
      # TODO
      arandr
      cbatticon
      shfmt
      # i3lock-fancy
      trayer
      pasystray
      # shellcheck
      #lxappearance
      libreoffice
      neofetch
      pavucontrol
      playerctl
      spotify
      xfce.xfce4-clipman-plugin
      xfce.xfce4-screenshooter
      texlive.combined.scheme-medium
      # volumeicon
      ubuntu_font_family
      #nerdfonts
      udisks
      w3m
      zathura
      zotero
      lapack
    ];

    services.network-manager-applet.enable = true;

    fonts.fontconfig.enable = true;
    # TODO create a service
    # services.keepassxc.enable = true;

    programs.home-manager.enable = true;

    # home.file = mkIf cfg.initDirectoryStructure {
    #   "${cfg.configDir}/.blank".text = mkBefore "";
    #   "${cfg.cacheDir}/.blank".text = mkBefore "";
    #   "${cfg.appDataDir}/.blank".text = mkBefore "";
    #   "${cfg.appStateDir}/.blank".text = mkBefore "";

    #   "${cfg.downloadsDir}/.blank".text =
    #     mkIf (cfg.downloadsDir != null) (mkBefore "");
    #   "${cfg.orgDir}/.blank".text =
    #     mkIf (cfg.orgDir != null) (mkBefore "");
    #   "${cfg.projectsDir}/.blank".text =
    #     mkIf (cfg.projectsDir != null) (mkBefore "");
    #   "${cfg.miscDataDir}/.blank".text =
    #     mkIf (cfg.miscDataDir != null) (mkBefore "");
    # };
  };
}
