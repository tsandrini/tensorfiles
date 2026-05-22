# --- flake-parts/modules/nixos/security/hardening/base.nix
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

  cfg = config.tensorfiles.security.hardening.base;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.security.hardening.base = {
    enable = mkEnableOption ''
      Enables the **base** security hardening profile.

      Applies a small, broadly-safe set of kernel/sysctl hardenings:
      kernel-pointer info-leak restrictions (`kptr_restrict`,
      `dmesg_restrict`), unprivileged eBPF restriction + JIT hardening,
      restricted-mode `ptrace`, wheel-only `su`, `/tmp` cleared on boot.

      On non-container hosts it also adds kernel cmdline mitigations
      (`init_on_alloc`, `init_on_free`, `page_alloc.shuffle`,
      `randomize_kstack_offset`) and a blacklist of dead network protocols
      and legacy filesystems that recurringly produce CVEs.

      Designed to be a no-op for normal workloads. Both `desktop` and
      `server` hardening profiles inherit this base layer.
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      # Kernel info-leak + privilege restrictions. Cheap, broadly applicable.
      boot.kernel.sysctl = {
        # Hide kernel pointers from non-root readers of /proc, dmesg, etc.
        "kernel.kptr_restrict" = _ 2;
        # Restrict access to dmesg to CAP_SYSLOG.
        "kernel.dmesg_restrict" = _ 1;
        # Block unprivileged use of bpf(2); harden the BPF JIT against spraying.
        "kernel.unprivileged_bpf_disabled" = _ 1;
        "net.core.bpf_jit_harden" = _ 2;
        # ptrace: restricted — only direct ancestors can trace. Doesn't break
        # gdb on your own children, blocks `strace -p <other-uid-pid>` games.
        "kernel.yama.ptrace_scope" = _ 1;
      };

      # Only members of `wheel` can invoke su/sudo at all.
      security.sudo.execWheelOnly = _ true;

      # Clear /tmp on every boot. Overridable per-host via mkForce if needed.
      boot.tmp.cleanOnBoot = _ true;
    }
    # |----------------------------------------------------------------------| #
    # Host/VM only — these are no-ops inside an LXC since the container
    # shares the host's kernel and cannot influence kernel cmdline or
    # load/blacklist modules.
    (mkIf (!config.boot.isContainer) {
      # NOTE: plain list assignment (no _) so we merge with whatever the
      # hardware/host module already added.
      boot.kernelParams = [
        # Zero memory on alloc + free to mitigate use-after-free leaks.
        "init_on_alloc=1"
        "init_on_free=1"
        # Randomize freelist order in the page allocator.
        "page_alloc.shuffle=1"
        # Randomize kernel stack offset on every syscall.
        "randomize_kstack_offset=on"
      ];

      # Dead/rare protocols and legacy filesystems that periodically produce
      # CVEs and that nothing on a typical host needs autoloaded.
      boot.blacklistedKernelModules = [
        # Dead network protocols
        "dccp"
        "sctp"
        "rds"
        "tipc"
        "ax25"
        "decnet"
        "x25"
        "netrom"
        "rose"
        "atm"
        "appletalk"
        "ipx"
        # Legacy/exotic filesystems (re-enable per-host if you use one)
        "cramfs"
        "freevxfs"
        "jffs2"
        "hfs"
        "hfsplus"
        "udf"
        # NOTE: `thunderbolt` and `firewire-core` are real DMA attack surface
        # but blacklisting them breaks docking stations and external GPUs.
        # Opt in per-host if you care.
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
