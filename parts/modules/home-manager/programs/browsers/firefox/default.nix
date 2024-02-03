# --- parts/modules/home-manager/programs/browsers/firefox.nix
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
  localFlake,
  inputs,
}: {
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit
    (localFlake.lib)
    mkOverrideAtHmModuleLevel
    isModuleLoadedAndEnabled
    mkImpermanenceEnableOption
    ;

  cfg = config.tensorfiles.hm.programs.browsers.firefox;
  _ = mkOverrideAtHmModuleLevel;

  plasmaCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.profiles.graphical-plasma";

  impermanenceCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
  pathToRelative = strings.removePrefix "${config.home.homeDirectory}/";
in {
  options.tensorfiles.hm.programs.browsers.firefox = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    impermanence = {enable = mkImpermanenceEnableOption;};
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.firefox = {
        enable = _ true;
        package = pkgs.firefox.override {
          # trace: warning: The cfg.enableTridactylNative argument for
          # `firefox.override` is deprecated, please add `pkgs.tridactyl-native`
          # to `nativeMessagingHosts.packages` instead
          nativeMessagingHosts = with pkgs; ([tridactyl-native] ++ (optional plasmaCheck plasma-browser-integration));
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
                # uBlock settings are written in JSON to be more compatible with the
                # backup format. This checks the syntax.
                adminSettings =
                  builtins.fromJSON
                  (builtins.readFile ./ublock-settings.json);
              };
            };
          };
        };
        profiles.default = {
          id = _ 0;
          name = _ "Default";
          isDefault = _ true;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; ([
              # ~ Privacy & content blocking
              ublock-origin
              skip-redirect
              multi-account-containers

              # ~ Utils
              keepassxc-browser
              tridactyl
              behave
              header-editor
              pywalfox
              enhancer-for-youtube

              # DEV related
              vue-js-devtools
            ]
            ++ (optional plasmaCheck plasma-integration));
          bookmarks = import ./bookmarks.nix;
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
                iconUpdateURL = "https://assets.kagi.com/v1/favicon-32x32.png";
                definedAliases = ["@k"];
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
                definedAliases = ["@np"];
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
                definedAliases = ["@no"];
              };
              "NixOS Wiki" = {
                urls = [
                  {
                    template = "https://nixos.wiki/index.php?search={searchTerms}";
                  }
                ];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@nw"];
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
            "services.sync.engine.bookmarks" = _ false;
            "services.sync.engine.tabs" = _ true;
            "services.sync.engine.addons" = _ false;
            "services.sync.declinedEngines" =
              _ "passwords,creditcards,addons,prefs,bookmarks";
          };

          # Download areknfox-user-js and append overrides (order matters)
          #
          # Note: I try to keep general purpose config in the settings
          # attrset listed above
          extraConfig =
            (builtins.readFile "${inputs.arkenfox-user-js}/user.js")
            + ''
              user_pref("extensions.autoDisableScopes", 0);

              // 2811: sanitize everything but keep history & downloads and
              // also enable session restore
              user_pref("browser.startup.page", 3);
              user_pref("privacy.clearOnShutdown.history", false);
              user_pref("privacy.clearOnShutdown.downloads", false);

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
        };
      };
    }
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

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
