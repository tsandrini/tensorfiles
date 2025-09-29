# --- flake-parts/modules/home-manager/programs/browsers/firefox.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
{ localFlake, inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    optional
    ;
  inherit (lib.strings) removePrefix;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkImpermanenceEnableOption;

  cfg = config.tensorfiles.hm.programs.browsers.firefox;
  _ = mkOverrideAtHmModuleLevel;

  plasmaCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.profiles.graphical-plasma";

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence = if impermanenceCheck then config.tensorfiles.hm.system.impermanence else { };
  pathToRelative = removePrefix "${config.home.homeDirectory}/";

  userjsEnabled = cfg.userjs.arkenfox.enable || cfg.userjs.betterfox.enable;
  userjs =
    if cfg.userjs.arkenfox.enable then
      cfg.userjs.arkenfox
    else if cfg.userjs.betterfox.enable then
      cfg.userjs.betterfox
    else
      { };
in
{
  options.tensorfiles.hm.programs.browsers.firefox = {
    enable = mkEnableOption ''
      TODO
    '';

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };

    userjs = {
      arkenfox = {
        enable = mkEnableOption ''
          Enable arkenfox user.js configuration.
        '';

        src = mkOption {
          type = types.path;
          default = "${inputs.arkenfox-user-js}/user.js";
          description = ''
            The path to the arkenfox user.js configuration.
          '';
        };

        extraConfig = mkOption {
          type = types.lines;
          default = ''
            user_pref("extensions.autoDisableScopes", 0);

            // 2811: sanitize everything but keep history & downloads and
            // also enable session restore
            user_pref("browser.startup.page", 3);
            user_pref("privacy.clearOnShutdown.history", false);
            user_pref("privacy.clearOnShutdown.downloads", false);
            user_pref("privacy.sanitize.sanitizeOnShutdown", false);

            // TODO: think off a better way to declaratively manage
            // cookie exepctions
            user_pref("privacy.clearOnShutdown.cookies", false);
            user_pref("privacy.clearOnShutdown.cache", false);
            user_pref("privacy.clearOnShutdown.sessions", false);

            // 4504: TODO figure out some alternative since I cannot stand
            // how it works by default but I'd like to have it
            // enabled at some point
            user_pref("privacy.resistFingerprinting.letterboxing", false);

            // 4510: I cannot f*ing stand light theme
            user_pref("browser.display.use_system_colors", false);
            user_pref("browser.theme.content-theme", 0);
            user_pref("browser.theme.toolbar-theme", 0);
            // tell websites to prefer dark colorscheme
            user_pref("layout.css.prefers-color-scheme.content-override", 0);
          '';
          description = ''
            Default extra configuration (overrides) for the arkenfox user.js.
          '';
        };
      };

      betterfox = {
        enable = mkEnableOption ''
          Enable betterfox user.js configuration.
        '';

        src = mkOption {
          type = types.path;
          default = "${inputs.betterfox}/user.js";
          description = ''
            The path to the betterfox user.js configuration.
          '';
        };

        extraConfig = mkOption {
          type = types.lines;
          default = ''
            // PREF: disable login manager
            user_pref("signon.rememberSignons", false);

            // PREF: disable address and credit card manager
            user_pref("extensions.formautofill.addresses.enabled", false);
            user_pref("extensions.formautofill.creditCards.enabled", false);

            // PREF: do not allow embedded tweets, Instagram, Reddit, and Tiktok posts
            user_pref("urlclassifier.trackingSkipURLs", "");
            user_pref("urlclassifier.features.socialtracking.skipURLs", "");

            // PREF: require safe SSL negotiation
            // [ERROR] SSL_ERROR_UNSAFE_NEGOTIATION
            user_pref("security.ssl.require_safe_negotiation", true);

            // PREF: disable telemetry of what default browser you use [WINDOWS]
            user_pref("default-browser-agent.enabled", false);

            // PREF: enforce certificate pinning
            // [ERROR] MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE
            // 1 = allow user MiTM (such as your antivirus) (default)
            // 2 = strict
            user_pref("security.cert_pinning.enforcement_level", 2);

            // PREF: enable HTTPS-Only Mode
            // Warn me before loading sites that don't support HTTPS
            // in both Normal and Private Browsing windows.
            user_pref("dom.security.https_only_mode", true);
            user_pref("dom.security.https_only_mode_error_page_user_suggestions", true);

            // This has unironically real life issues
            user_pref("privacy.resistFingerprinting.spoofTimezone", false);

            /****************************************************************************************
            * OPTION: INSTANT SCROLLING (SIMPLE ADJUSTMENT)                                       *
            ****************************************************************************************/
            // recommended for 60hz+ displays
            user_pref("apz.overscroll.enabled", true); // DEFAULT NON-LINUX
            user_pref("general.smoothScroll", true); // DEFAULT
            user_pref("mousewheel.default.delta_multiplier_y", 275); // 250-400; adjust this number to your liking
            // Firefox Nightly only:
            // [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1846935
            user_pref("general.smoothScroll.msdPhysics.enabled", false); // [FF122+ Nightly]
          '';
          description = ''
            Default extra configuration (overrides) for the betterfox user.js.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [

    # |----------------------------------------------------------------------| #
    {
      assertions = [
        {
          assertion =
            (cfg.userjs.arkenfox.enable && !cfg.userjs.betterfox.enable)
            || (!cfg.userjs.arkenfox.enable && cfg.userjs.betterfox.enable);
          message = "Only one user.js backend can be enabled at a time.";
        }
      ];
    }
    # |----------------------------------------------------------------------| #
    {
      programs.firefox = {
        enable = _ true;
        package = pkgs.firefox.override {
          # trace: warning: The cfg.enableTridactylNative argument
          # `firefox.override` is deprecated, please add `pkgs.tridactyl-native`
          # to `nativeMessagingHosts.packages` instead
          nativeMessagingHosts =
            with pkgs;
            ([ tridactyl-native ] ++ (optional plasmaCheck kdePackages.plasma-browser-integration));
          extraPolicies = {
            CaptivePortal = false;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableTelemetry = true;
            DisableFirefoxAccounts = false;
            # NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
            OfferToSaveLoginsDefault = false;
            PasswordManagerEnabled = false;
            FirefoxHome = {
              Search = true;
              Pocket = false;
              Snippets = false;
              TopSites = false;
              Highlights = false;
            };
            UserMessaging = {
              ExtensionRecommendations = false;
              SkipOnboarding = true;
            };
            "3rdparty".Extensions = {
              "uBlock0@raymondhill.net" = {
                adminSettings = {
                  permissions = [ "internal:privateBrowsingAllowed" ];
                  dynamicFilteringString = "behind-the-scene * * noop\nbehind-the-scene * inline-script noop\nbehind-the-scene * 1p-script noop\nbehind-the-scene * 3p-script noop\nbehind-the-scene * 3p-frame noop\nbehind-the-scene * image noop\nbehind-the-scene * 3p noop\n* * 3p-script block\n* * 3p-frame block\n* * 3p block";
                  hostnameSwitchesString = "no-large-media: behind-the-scene false\nno-csp-reports: * true";
                  userFiltersTrusted = true;
                  userSettings = {
                    advancedUserEnabled = false;
                    uiTheme = "dark";
                    importedLists = [
                      "https://raw.githubusercontent.com/laylavish/uBlockOrigin-HUGE-AI-Blocklist/main/list.txt"
                      "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt"
                    ];
                  };
                  selectedFilterLists = [
                    "CZE-0"
                    "adguard-cookies"
                    "adguard-generic"
                    "adguard-mobile-app-banners"
                    "adguard-other-annoyances"
                    "adguard-popup-overlays"
                    "adguard-social"
                    "adguard-spyware-url"
                    "adguard-widgets"
                    "block-lan"
                    "curben-phishing"
                    "easylist"
                    "easylist-annoyances"
                    "easylist-chat"
                    "easylist-newsletters"
                    "easylist-notifications"
                    "easyprivacy"
                    "fanboy-cookiemonster"
                    "fanboy-social"
                    "fanboy-thirdparty_social"
                    "plowe-0"
                    "ublock-abuse"
                    "ublock-annoyances"
                    "ublock-badware"
                    "ublock-cookies-adguard"
                    "ublock-cookies-easylist"
                    "ublock-filters"
                    "ublock-privacy"
                    "ublock-quick-fixes"
                    "ublock-unbreak"
                    "urlhaus-1"
                    "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt"
                    "https://raw.githubusercontent.com/laylavish/uBlockOrigin-HUGE-AI-Blocklist/main/list.txt"
                  ];
                };
              };
            };
          };
        };
        profiles.default = {
          id = _ 0;
          name = _ "Default";
          isDefault = _ true;
          extensions.packages =
            with pkgs.nur.repos.rycee.firefox-addons;
            (
              [
                # ~ Privacy & content blocking
                ublock-origin # Finally, an efficient wide-spectrum content blocker. Easy on CPU and memory.
                skip-redirect # This add-on tries to extract the final url from the intermediary url and goes there straight away if successful.
                multi-account-containers # Firefox Multi-Account Containers lets you keep parts of your online life separated into color-coded tabs.

                # ~ Utils
                keepassxc-browser # Official browser plugin for the KeePassXC password manager
                tridactyl # Vim, but in your browser. Replace Firefox’s control mechanism with one modelled on Vim.
                # header-editor # Manage browser’s requests, include modify the request headers and response headers, redirect requests, cancel requests
                pywalfox # Dynamic theming of Firefox using your Pywal colors
                # enhancer-for-youtube # Take control of YouTube and boost your user experience!
                # sidebery # Vertical tabs tree and bookmarks in sidebar with advanced containers configuration, grouping and many other features.
                sponsorblock # Easily skip YouTube video sponsors
                aw-watcher-web # This extension logs the current tab and your browser activity to ActivityWatch.
                darkreader # Dark mode for every website. Take care of your eyes, use dark theme for night and daily browsing.

                # DEV related
                vue-js-devtools # DevTools extension for debugging Vue.js applications.
                react-devtools # React Developer Tools is a tool that allows you to inspect a React tree, including the component hierarchy, props, state, and more.
                octotree # GitHub on steroids
                refined-github # Simplifies the GitHub interface and adds many useful features.
              ]
              ++ (optional plasmaCheck plasma-integration)
            );
          # bookmarks = import ./bookmarks.nix;
          search = {
            force = _ true;
            default = _ "Kagi";
            engines = {
              "Kagi" = {
                urls = [
                  {
                    # template = "https://nixos.wiki/index.php?search={searchTerms}";
                    template = "https://kagi.com/search?q={searchTerms}";
                  }
                ];
                icon = "https://assets.kagi.com/v1/favicon-32x32.png";
                definedAliases = [ "@k" ];
              };
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };
              "NixOS Wiki" = {
                urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
                icon = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = [ "@nw" ];
              };
            };
          };
          settings = {
            # ~ UI
            "general.smoothScroll" = _ true;
            "browser.uidensity" = _ 1;
            "devtools.theme" = _ "dark";
            "browser.download.panel.shown" = _ true;
            "browser.theme.content-theme" = _ 0;
            "browser.theme.toolbar-theme" = _ 0;

            # Vertical tabs
            "sidebar.verticalTabs" = _ true;
            "sidebar.revamp" = _ true;
            "browser.tabs.closeTabByDblclick" = _ true;
            "browser.toolbars.bookmarks.visibility" = _ "never";

            "browser.newtabpage.activity-stream.feeds.section.highlights" = _ true;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = _ true;
            "browser.newtabpage.activity-stream.feeds.telemetry" = _ false;
            "browser.newtabpage.activity-stream.feeds.topsites" = _ true;
            "browser.newtabpage.activity-stream.section.highlights.rows" = _ 2;
            "browser.newtabpage.activity-stream.showSponsored" = _ false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = _ false;
            "browser.newtabpage.activity-stream.telemetry" = _ false;
            "browser.startup.page" = _ 3;

            # ~ General settings
            "extensions.ui.locale.hidden" = _ true;
            "extensions.ui.sitepermission.hidden" = _ true;
            "extensions.screenshots.disabled" = _ true;
            "browser.download.dir" = _ config.home.sessionVariables.DOWNLOADS_DIR;

            # Let Nix manage extensions
            "app.update.auto" = _ false;
            "extensions.update.enabled" = _ false;

            # # ~ User testing
            "experiments.activeExperiment" = _ false;
            "experiments.enabled" = _ false;
            "experiments.supported" = _ false;
            "network.allow-experiments" = _ false;
            "extensions.experiments.enabled" = _ false;

            # ~ Ff sync
            # "services.sync.username" = _ userEmail;
            "services.sync.engine.passwords" = _ false;
            "services.sync.engine.prefs" = _ false;
            "services.sync.engine.history" = _ true;
            "services.sync.engine.creditcards" = _ false;
            "services.sync.engine.bookmarks" = _ true;
            "services.sync.engine.tabs" = _ true;
            "services.sync.engine.addons" = _ false;
            "services.sync.declinedEngines" = _ "passwords,creditcards,addons,prefs,bookmarks";
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf userjsEnabled {
      programs.firefox.profiles.default.extraConfig = (builtins.readFile userjs.src) + userjs.extraConfig;
    })
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [
          ".mozilla/firefox"
          (pathToRelative "${config.xdg.cacheHome}/.mozilla/firefox")
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
