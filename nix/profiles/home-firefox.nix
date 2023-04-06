# --- profiles/home-firefox.nix
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
  home-manager.users.${user} = {

    # Set up browser related MIME types
    xdg.mimeApps.defaultApplications = lib.mkIf cfg.xdg.mimeApps.enable {
      "x-scheme-handler/http" = _ "firefox.desktop";
      "x-scheme-handler/https" = _ "firefox.desktop";
      "x-scheme-handler/about" = _ "firefox.desktop";
      "x-scheme-handler/unknown" = _ "firefox.desktop";
      "x-scheme-handler/chrome" = _ "firefox.desktop";
      "text/html" = _ "firefox.desktop";
      "application/x-extension-htm" = _ "firefox.desktop";
      "application/x-extension-html" = _ "firefox.desktop";
      "application/x-extension-shtml" = _ "firefox.desktop";
      "application/xhtml+xml" = _ "firefox.desktop";
      "application/x-extension-xhtml" = _ "firefox.desktop";
      "application/x-extension-xht" = _ "firefox.desktop";
      "application/x-www-browser" = _ "firefox.desktop";
      "x-www-browser" = _ "firefox.desktop";
      "x-scheme-handler/webcal" = _ "firefox.desktop";
    };

    xdg.mimeApps.associations.added = lib.mkIf cfg.xdg.mimeApps.enable {
      "x-scheme-handler/http" = _ "firefox.desktop";
      "x-scheme-handler/https" = _ "firefox.desktop";
      "x-scheme-handler/about" = _ "firefox.desktop";
      "x-scheme-handler/unknown" = _ "firefox.desktop";
      "x-scheme-handler/chrome" = _ "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = _ "firefox.desktop";
      "application/x-extension-html" = _ "firefox.desktop";
      "application/x-extension-shtml" = _ "firefox.desktop";
      "application/xhtml+xml" = _ "firefox.desktop";
      "application/x-extension-xhtml" = _ "firefox.desktop";
      "application/x-extension-xht" = _ "firefox.desktop";
      "application/x-www-browser" = _ "firefox.desktop";
      "x-www-browser" = _ "firefox.desktop";
      "x-scheme-handler/webcal" = _ "firefox.desktop";
    };

    programs.firefox = {
      enable = _ true;
      package = _ pkgs.firefox-devedition-bin;
    };
  };

  # environment.persistence = lib.mkIf (config.environment ? persistence) {
  #   "/persist".users.${user} = {
  #     directories = [
  #       # Config files should be dynamically provided by home-manager
  #       #".config"
  #       ".cache"
  #     ];
  #   };
  # };

}
