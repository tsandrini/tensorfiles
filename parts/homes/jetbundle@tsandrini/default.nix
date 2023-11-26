# --- parts/homes/jetbundle@tsandrini/default.nix
{
  config,
  pkgs,
  ...
}: {
  config = {
    # misc
    tensorfiles.hm.misc.xdg.enable = true;
    #tensorfiles.hm.misc.gtk.enable = true; # doesnt work unfortunately
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
    tensorfiles.hm.programs.browsers.firefox.enable = true;
    # security
    tensorfiles.hm.security.agenix.enable = true;
    # services
    tensorfiles.hm.services.dunst.enable = true;
    tensorfiles.hm.services.pywalfox-native.enable = true;
    tensorfiles.hm.services.x11.picom.enable = true;
    tensorfiles.hm.services.x11.redshift.enable = true;

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
      # chromium
      # other
      beeper
      armcord
      feh
      cbatticon
      mpv
      # TODO
      arandr
      cbatticon
      shfmt
      i3lock-fancy
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
      yazi
    ];

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
