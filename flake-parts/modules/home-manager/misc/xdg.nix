# --- flake-parts/modules/home-manager/misc/xdg.nix
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
{ localFlake }:
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    types
    mkOption
    mkEnableOption
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.misc.xdg;
  _ = mkOverrideAtHmModuleLevel;

  defaultBrowser =
    if cfg.defaultApplications.browser != null then
      cfg.defaultApplications.browser
    else
      (
        if config.home.sessionVariables.BROWSER != null then config.home.sessionVariables.BROWSER else null
      );

  defaultEditor =
    if cfg.defaultApplications.editor != null then
      cfg.defaultApplications.editor
    else
      (if config.home.sessionVariables.EDITOR != null then config.home.sessionVariables.EDITOR else null);

  defaultTerminal =
    if cfg.defaultApplications.terminal != null then
      cfg.defaultApplications.terminal
    else
      (
        if config.home.sessionVariables.TERMINAL != null then
          config.home.sessionVariables.TERMINAL
        else
          null
      );

  defaultEmail =
    if cfg.defaultApplications.email != null then
      cfg.defaultApplications.email
    else
      (if config.home.sessionVariables.EMAIL != null then config.home.sessionVariables.EMAIL else null);
in
{
  options.tensorfiles.hm.misc.xdg = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the xdg toolset.
    '';

    defaultApplications = {
      enable =
        mkEnableOption ''
          TODO
        ''
        // {
          default = true;
        };

      browser = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          TODO
        '';
      };

      editor = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          TODO
        '';
      };

      terminal = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          TODO
        '';
      };

      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          TODO
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      xdg = {
        enable = _ true;
        mime.enable = _ true;
        mimeApps.enable = _ true;
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.defaultApplications.enable {
      xdg.mimeApps = {
        defaultApplications = {
          # BROWSER
          "x-scheme-handler/http" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-scheme-handler/https" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-scheme-handler/about" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-scheme-handler/unknown" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-scheme-handler/chrome" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "text/html" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-extension-htm" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-extension-html" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-extension-shtml" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/xhtml+xml" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-extension-xhtml" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-extension-xht" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "application/x-www-browser" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-www-browser" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          "x-scheme-handler/webcal" = mkIf (defaultBrowser != null) (_ "${defaultBrowser}.desktop");
          # EDITOR
          "application/x-shellscript" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "application/x-perl" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "application/json" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-readme" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/plain" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/markdown" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-csrc" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-chdr" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-python" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-makefile" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          "text/x-markdown" = mkIf (defaultEditor != null) (_ "${defaultEditor}.desktop");
          # TERMINAL
          "mimetype" = mkIf (defaultTerminal != null) (_ "${defaultTerminal}.desktop");
          "application/x-terminal-emulator" = mkIf (defaultTerminal != null) (_ "${defaultTerminal}.desktop");
          "x-terminal-emulator" = mkIf (defaultTerminal != null) (_ "${defaultTerminal}.desktop");
          # EMAIL
          "x-scheme-handler/mailto" = mkIf (defaultEmail != null) (_ "${defaultEmail}.desktop");
          "x-scheme-handler/mid" = mkIf (defaultEmail != null) (_ "${defaultEmail}.desktop");
          "message/rfc822" = mkIf (defaultEmail != null) (_ "${defaultEmail}.desktop");
        };
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
