# --- flake-parts/modules/nixos/security/hardening/desktop.nix
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
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.security.hardening.desktop;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.security.hardening.desktop = {
    enable = mkEnableOption ''
      Enables the **desktop** security hardening profile.

      Inherits `tensorfiles.security.hardening.base` and adds a small set
      of desktop-focused tweaks. Crucially, it pins unprivileged user
      namespaces ENABLED — Steam, Chromium/Firefox sandbox, bubblewrap and
      rootless podman all depend on them. Stating it explicitly here makes
      any future drift loud rather than silent.

      Intended for the workstation hosts (laptops, gaming machines).
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.security.hardening.base.enable = _ true;

      # Pin unprivileged user namespaces ON.
      # Already the NixOS default; restated so a future flip is visible.
      # Required by: Steam, Chromium/Firefox sandbox, bubblewrap, podman-rootless.
      boot.kernel.sysctl."kernel.unprivileged_userns_clone" = _ 1;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
