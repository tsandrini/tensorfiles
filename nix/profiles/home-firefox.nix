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
      package = pkgs.firefox-devedition-bin.override {
        cfg.enableTridactylNative = true;
      };

      profiles.default = {
        id = _ 0;
        isDefault = _ true;
        extraConfig = _ "";
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          # missing: https-everywhere
          # BASE
          ublock-origin
          noscript
          cookie-autodelete
          privacy-badger
          keepassxc-browser
          enhancer-for-youtube
          # vimium-c
          tridactyl
          pywalfox

          # DEV related
          vue-js-devtools
        ];
        settings = {
          # ~ UI
          "browser.uidensity" = _ 1;
          "browser.toolbars.bookmarks.visibility" = _ "always";
          "devtools.theme" = _ "dark";

          "browser.contentblocking.category" = _ "strict";
          "browser.discovery.enabled" = _ false;


          # Let Nix manage extensions
          "app.update.auto" = _ false;
          "extensions.update.enabled" = _ false;
          "extensions.ui.locale.hidden" = _ true;
          "extensions.ui.sitepermission.hidden" = _ true;
          "extensions.screenshots.disabled" = _ true;
          "extensions.autoDisableScopes" = _ 0;
          "privacy.donottrackheader.enabled" = _ true;

          "browser.download.dir" = _ "${cfg.home.homeDirectory}/Downloads";

          # ~ Telemetry
          "browser.newtabpage.activity-stream.feeds.telemetry" = _ false;
          "browser.newtabpage.activity-stream.telemetry" = _ false;
          "browser.ping-centre.telemetry" = _ false;
          "toolkit.telemetry.archive.enabled" = _ false;
          "toolkit.telemetry.bhrPing.enabled" = _ false;
          "toolkit.telemetry.enabled" = _ false;
          "toolkit.telemetry.firstShutdownPing.enabled" = _ false;
          "toolkit.telemetry.hybridContent.enabled" = _ false;
          "toolkit.telemetry.newProfilePing.enabled" = _ false;
          "toolkit.telemetry.reportingpolicy.firstRun" = _ false;
          "toolkit.telemetry.shutdownPingSender.enabled" = _ false;
          "toolkit.telemetry.unified" = _ false;
          "toolkit.telemetry.updatePing.enabled" = _ false;

          # ~ User testing
          "experiments.activeExperiment" = _ false;
          "experiments.enabled" = _ false;
          "experiments.supported" = _ false;
          "network.allow-experiments" = _ false;
          "extensions.experiments.enabled" = _ false;
        };
      };
    };
  };

  environment.persistence = lib.mkIf (config.environment ? persistence) {
    "/persist".users.${user} = {
      directories = [
        ".mozilla/firefox/default"
      ];
    };
  };
}
