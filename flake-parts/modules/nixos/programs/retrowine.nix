# --- flake-parts/modules/nixos/programs/retrowine.nix
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
{ localFlake }:
{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    literalExpression
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.programs.retrowine;
  _ = mkOverrideAtModuleLevel;

  # NOTE: uaccess is applied by 73-seat-late.rules, so this can't live in
  # services.udev.extraRules (= 99-local.rules, too late to take effect).
  udevRules = pkgs.writeTextFile {
    name = "retrowine-udev-rules";
    destination = "/etc/udev/rules.d/70-retrowine.rules";
    text = ''
      # Wine derives a CD's volume label + serial from the raw device, and
      # udisks-made loop devices are root:disk. Seat user may read optical images.
      SUBSYSTEM=="block", KERNEL=="loop[0-9]*", ENV{ID_FS_TYPE}=="iso9660|udf", TAG+="uaccess"
    '';
  };
in
{
  options.tensorfiles.programs.retrowine = {
    enable = mkEnableOption ''
      Enables `retrowine`, the disc-backup + Wine launcher for 2000s-era
      Windows games, together with the system-side pieces it relies on:

      - 32-bit graphics drivers (it runs a pure 32-bit Wine) and the 32-bit
        ALSA bridge of PipeWire (`AUDIO_DRIVER='alsa'`, needed for MIDI),
      - `udf` exempted from the `tensorfiles.security.hardening.base`
        kernel module blacklist (DVDs and most disc images),
      - read access for the seat user to loop devices holding `iso9660`/`udf`
        images, so that Wine reports the image's real volume label and serial
        and label/serial based disc checks pass from a backup.
    '';

    package = mkOption {
      type = types.package;
      default = localFlake.packages.${system}.retrowine;
      defaultText = literalExpression "tensorfiles.packages.\${system}.retrowine";
      description = ''
        The retrowine package to install. Only exists on `x86_64-linux`.
      '';
    };

    root = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/run/media/alice/0123-4567/games-backup";
      description = ''
        Directory holding the backups (disc images + per-game `game.conf`),
        exported as `RETROWINE_ROOT`. When `null` retrowine falls back to
        `$XDG_DATA_HOME/retrowine`.
      '';
    };

    cdemu = {
      enable =
        mkEnableOption ''
          CDemu, a virtual optical drive (`/dev/srN` backed by the `vhba` kernel
          module). Unlike a loop mount it answers TOC queries and can load
          bin/cue images, which mixed-mode (audio track) discs and stricter
          disc checks need. Users have to be in the `cdrom` group to use it.
        ''
        // {
          default = true;
        };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      assertions = [
        {
          assertion = localFlake.packages.${system} ? retrowine;
          message = "tensorfiles.programs.retrowine: the package needs a 32-bit wine and only exists on x86_64-linux.";
        }
      ];

      environment.systemPackages = [ cfg.package ];
      services.udev.packages = [ udevRules ];

      hardware.graphics.enable32Bit = _ true;
      # NOTE: wine's ALSA driver is the only one with MIDI out, and wine is 32-bit here
      services.pipewire.alsa.support32Bit = mkIf config.services.pipewire.alsa.enable (_ true);

      # NOTE: plain list, merges with the exemptions of hosts/other modules.
      tensorfiles.security.hardening.base.allowedKernelModules = [ "udf" ];
    }
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.root != null) {
      environment.sessionVariables.RETROWINE_ROOT = _ cfg.root;
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.cdemu.enable {
      programs.cdemu = {
        enable = _ true;
        gui = _ false;
        image-analyzer = _ false;
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
