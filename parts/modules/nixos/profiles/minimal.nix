# --- parts/modules/nixos/profiles/minimal.nix
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
  inherit (tensorfiles) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.minimal;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.profiles.minimal = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the minimal system profile.

      **Minimal layers** builds on top of the base layer and creates a
      minimal bootable system. It isn't targeted to posses any other functionality,
      for example if you'd like remote access and more of server-like features,
      use the headless profile that build on top of this one.
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.base.enable = _ true;

        tasks.nix-garbage-collect.enable = _ true;
        tasks.system-autoupgrade.enable = _ true;
      };

      time.timeZone = _ "Europe/Prague";
      i18n.defaultLocale = _ "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = _ "cs_CZ.UTF-8";
        LC_IDENTIFICATION = _ "cs_CZ.UTF-8";
        LC_MEASUREMENT = _ "cs_CZ.UTF-8";
        LC_MONETARY = _ "cs_CZ.UTF-8";
        LC_NAME = _ "cs_CZ.UTF-8";
        LC_NUMERIC = _ "cs_CZ.UTF-8";
        LC_PAPER = _ "cs_CZ.UTF-8";
        LC_TELEPHONE = _ "cs_CZ.UTF-8";
        LC_TIME = _ "cs_CZ.UTF-8";
      };

      console = {
        enable = _ true;
        useXkbConfig = _ true;
        font = _ "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
      };

      environment.systemPackages = with pkgs; [
        # BASE UTILS
        htop
        wget
        curl
        jq
        killall
        openssl
        vim
        calcurse
        w3m

        dosfstools
        exfatprogs
        udisks
        pciutils
        usbutils
        iotop
        hw-probe
        ntfs3g

        atool
        gzip
        lz4
        lzip
        lzop
        p7zip
        rar
        unrar
        rzip
        unzip
        xz
        zip
        zstd

        sqlite
        sqlitebrowser

        libarchive
        libbtbb
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
