# --- modules/programs/alacritty.nix
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
  lib,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.programs.newsboat;
  _ = mkOverrideAtModuleLevel;

  urlType = types.listOf (types.submodule {
    options = {
      url = mkOption {
        type = types.str;
        example = "http://example.com";
        description = "Feed URL.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["foo" "bar"];
        description = "Feed tags.";
      };

      title = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "ORF News";
        description = "Feed title.";
      };
    };
  });
in {
  options.tensorfiles.programs.newsboat = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the newsboat rss reader.
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        urls = {
          news = {
            enable = mkAlreadyEnabledOption (mdDoc ''
              Enable the addition of news related urls into the newsboat
              rss reader.
            '');

            urls = mkOption {
              type = urlType;
              default = [
                {
                  url = "https://www.novinky.cz/rss";
                  tags = ["news" "czech"];
                }
                {
                  url = "https://zpravy.aktualne.cz/rss/";
                  tags = ["news" "czech"];
                }
                {
                  url = "https://www.krimi-plzen.cz/rss";
                  tags = ["news" "czech"];
                }
                {
                  url = "https://www.irozhlas.cz/rss/irozhlas";
                  tags = ["news" "czech"];
                }
                {
                  url = "http://feeds.feedburner.com/odemcene-clanky";
                  tags = ["news" "czech"];
                }
                {
                  url = "https://www.theguardian.com/international/rss";
                  tags = ["news" "english"];
                }
              ];
              description = mdDoc ''
                News source urls for the newsboat rss reader
              '';
            };
          };

          tech = {
            enable = mkAlreadyEnabledOption (mdDoc ''
              Enable the addition of tech related urls into the newsboat
              rss reader.
            '');

            urls = mkOption {
              type = urlType;
              default = [
                {
                  url = "https://root.cz/rss/clanky";
                  tags = ["tech" "czech"];
                }
                {
                  url = "https://root.cz/rss/zpravicky";
                  tags = ["tech" "czech"];
                }
                {
                  url = "https://www.archlinux.org/feeds/news/";
                  tags = ["tech" "english"];
                }
                {
                  url = "https://news.ycombinator.com/rss";
                  tags = ["tech" "english"];
                }
                {
                  url = "https://feeds.arstechnica.com/arstechnica/index";
                  tags = ["tech" "english"];
                }
              ];
              description = mdDoc ''
                Tech source urls for the newsboat rss reader
              '';
            };
          };

          sci = {
            enable = mkAlreadyEnabledOption (mdDoc ''
              Enable the addition of science related urls into the newsboat
              rss reader.
            '');

            urls = mkOption {
              type = urlType;
              default = [
                {
                  url = "https://vesmir.cz/cz/vesmir-rss-odemcene-clanky.html";
                  tags = ["sci" "czech"];
                }
                {
                  url = "https://www.mff.cuni.cz/cs/articlesRss";
                  tags = ["sci" "czech"];
                }
                {
                  url = "https://api.quantamagazine.org/feed/";
                  tags = ["sci" "english"];
                }
                {
                  url = "http://feeds.nature.com/nature/rss/current";
                  tags = ["sci" "english"];
                }
                {
                  url = "http://export.arxiv.org/rss/quant-ph";
                  tags = ["sci" "english" "papers"];
                }
                {
                  url = "http://export.arxiv.org/rss/math-ph";
                  tags = ["sci" "english" "papers"];
                }
                {
                  url = "http://export.arxiv.org/rss/gr-qc";
                  tags = ["sci" "english" "papers"];
                }
                {
                  url = "http://export.arxiv.org/rss/cs";
                  tags = ["sci" "english" "papers"];
                }
              ];
              description = mdDoc ''
                Science source urls for the newsboat rss reader
              '';
            };
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
      in {
        home.packages = with pkgs; [w3m];

        programs.newsboat = {
          enable = _ true;
          extraConfig = mkBefore ''
            bind-key j down
            bind-key k up
            bind-key j next articlelist
            bind-key k prev articlelist
            bind-key J next-feed articlelist
            bind-key K prev-feed articlelist
            bind-key G end
            bind-key g home
            bind-key d pagedown
            bind-key u pageup
            bind-key l open
            bind-key h quit
            bind-key a toggle-article-read
            bind-key n next-unread
            bind-key N prev-unread
            bind-key D pb-download
            bind-key U show-urls
            bind-key x pb-delete
            bind-key ^t next-unread

            color info default default reverse
            color listnormal_unread yellow default
            color listfocus blue default reverse bold
            color listfocus_unread blue default reverse bold

            text-width 80
            html-renderer "${pkgs.w3m}/bin/w3m -dump -T text/html"
            confirm-exit no
            cleanup-on-quit no
          '';
        };
        #
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
