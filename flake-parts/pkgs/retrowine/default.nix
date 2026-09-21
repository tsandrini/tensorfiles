{
  lib,
  writeShellApplication,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  util-linux,
  systemd,
  udisks,
  ddrescue,
  cdemu-client,
  gawk,
  gamescope,
  winetricks,
  # NOTE: `wine` is the pure 32-bit build: win32 prefixes + 16-bit installer
  # stubs, which the WoW64 builds don't cover. Needs
  # `hardware.graphics.enable32Bit` on the host.
  wine,
}:
let
  # NOTE: upstream data race, still in 3.16.28: the host cursor wl_surface is
  # destroyed on one thread while the input thread hands it to
  # wl_pointer.set_cursor. Strict compositors (niri) disconnect the client and
  # gamescope abort()s -- on anything that swaps cursors under the pointer,
  # i.e. every installer and launcher menu. See the patch header.
  gamescope' = gamescope.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./gamescope-cursor-surface-race.patch ];
  });
in
writeShellApplication {
  name = "retrowine";

  runtimeInputs = [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    util-linux # losetup, findmnt, taskset
    systemd # udevadm
    udisks # udisksctl, rootless loop-mounting of images
    ddrescue
    cdemu-client # talks to the (system-provided) cdemu-daemon over D-Bus
    gawk
    gamescope'
    winetricks
    wine
  ];

  text = builtins.readFile ./retrowine.sh;

  meta = {
    description = "Disc imaging + per-game Wine prefixes for 2000s-era Windows games";
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
