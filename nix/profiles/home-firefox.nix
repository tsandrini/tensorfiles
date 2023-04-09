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

    home.file.".mozilla/native-messaging-hosts/tridactyl.json".text = let
      tridactyl = with pkgs.nimPackages;
        buildNimPackage {
          pname = "tridactyl_native";
          version = "dev";
          nimBinOnly = true;
          src = inputs.tridactyl-native-messenger;
          buildInputs = [ regex unicodedb tempfile ];
        };
    in builtins.toJSON {
      name = "tridactyl";
      description = "Tridactyl native command handler";
      path = "${tridactyl}/bin/native_main";
      type = "stdio";

      allowed_extensions = [
        "tridactyl.vim@cmcaine.co.uk"
        "tridactyl.vim.betas@cmcaine.co.uk"
        "tridactyl.vim.betas.nonewtab@cmcaine.co.uk"
      ];
    };

    home.file."${cfg.xdg.configHome}/tridactyl/tridactylrc".text = ''
      js tri.config.set("editorcmd", "alacritty -e nvim")
    '';

    programs.firefox = {
      enable = _ true;
      profiles.default = {
        id = _ 0;
        name = _ "default";
        isDefault = _ true;
        extraConfig = builtins.readFile "${inputs.arkenfox-user-js}/user.js";
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          # ~ Privacy & content blocking
          ublock-origin
          noscript
          cookie-autodelete
          privacy-badger
          decentraleyes
          clearurls

          # ~ Utils
          keepassxc-browser
          tridactyl
          enhancer-for-youtube
          pywalfox

          # DEV related
          vue-js-devtools
        ];
        search = {
          force = _ true;
          default = _ "DuckDuckGo";
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "channel"; value = "unstable"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "Nix Options" = {
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "channel"; value = "unstable"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };
          };
        };
        settings = {
          # ~ UI
          "general.smoothScroll" = _ true;
          "browser.toolbars.bookmarks.visibility" = _ "always";
          "browser.uidensity" = _ 1;
          "devtools.theme" = _ "dark";
          "browser.download.panel.shown" = _ true;
          "browser.theme.content-theme" = _ 0;
          "browser.theme.toolbar-theme" = _ 0;

          # ~ General settings
          "browser.discovery.enabled" = _ false;
          "extensions.ui.locale.hidden" = _ true;
          "extensions.ui.sitepermission.hidden" = _ true;
          "extensions.screenshots.disabled" = _ true;
          "extensions.autoDisableScopes" = _ 0;
          "browser.download.dir" = _ "${cfg.home.homeDirectory}/Downloads";

          # Let Nix manage extensions
          "app.update.auto" = _ false;
          "extensions.update.enabled" = _ false;

          # ~ General privacy settings
          "browser.contentblocking.category" = _ "strict";
          "privacy.resistFingerprinting" = _ true;
          "privacy.donottrackheader.enabled" = _ true;
          "privacy.trackingprotection.enabled" = _ true;
          "privacy.trackingprotection.cryptomining.enabled" = _ true;
          "browser.send_pings" = _ false;
          "browser.urlbar.speculativeConnect.enabled" = _ false;
          "dom.event.clipboardevents.enabled" = _ false;
          "media.eme.enabled" = _ false;
          "media.gmp-widevinecdm.enabled" = _ false;
          "media.navigator.enabled" = _ false;
          "network.cookie.cookieBehavior" = _ 1;
          "network.http.referer.XOriginPolicy" = _ 2;
          "network.http.referer.XOriginTrimmingPolicy" = _ 2;
          "webgl.disabled" = _ true;
          "browser.sessionstore.privacy_level" = _ 2;
          "beacon.enabled" = _ false;
          "browser.safebrowsing.downloads.remote.enabled" = _ false;
          "network.dns.disablePrefetch" = _ true;
          "network.dns.disablePrefetchFromHTTPS" = _ true;
          "network.predictor.enabled" = _ false;
          "network.predictor.enable-prefetch" = _ false;
          "network.prefetch-next" = _ false;
          "network.IDN_show_punycode" = _ true;

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

          # ~ Ff sync
          "services.sync.username" = _ "tomas.sandrini@seznam.cz";
          "services.sync.engine.passwords" = _ false;
          "services.sync.engine.prefs" = _ false;
          "services.sync.engine.history" = _ true;
          "services.sync.engine.creditcards" = _ false;
          "services.sync.engine.bookmarks" = _ true;
          "services.sync.engine.tabs" = _ true;
          "services.sync.engine.addons" = _ false;
          "services.sync.declinedEngines" = _ "passwords,creditcards,addons,prefs";
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
