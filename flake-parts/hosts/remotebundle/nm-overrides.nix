_: {
  nix-mineral.overrides.fileSystem.baseFileSystems = false;
  nix-mineral.overrides.fileSystem.specialFileSystems = true;

  # NOTE resolve warnings like this one
  # nginx.service: bpf-firewall: Attaching egress BPF program to cgroup /sys/fs/cgroup/system.slice/nginx.service failed: Invalid argument
  boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = "0";

  ## Compatibility
  # Options to ensure compatibility with certain usecases and hardware, at the
  # expense of overall security.

  # Set boot parameter "module.sig_enforce=0" to allow loading unsigned kernel
  # modules, which may include certain drivers. Lockdown must also be disabled,
  # see option below this one.
  # nix-mineral.overrides.compatibility.allow-unsigned-modules = true;

  # Disable Linux Kernel Lockdown to *permit* loading unsigned kernel modules
  # and hibernation.
  # nix-mineral.overrides.compatibility.no-lockdown = true;

  # Enable binfmt_misc. This is required for Roseta to function.
  # nix-mineral.overrides.compatibility.binfmt-misc = true;

  # Reenable the busmaster bit at boot. This may help with low resource systems
  # that are prevented from booting by the defaults of nix-mineral.
  # nix-mineral.overrides.compatibility.busmaster-bit = true;

  # Reenable io_uring, which is the cause of many vulnerabilities. This may
  # be desired for specific environments concerning Proxmox.
  # nix-mineral.overrides.compatibility.io-uring = true;

  # Enable ip forwarding. Useful for certain VM networking and is required if
  # the system is meant to function as a router.
  nix-mineral.overrides.compatibility.allow-ip-forward = true;

  ## Desktop
  # Options that are useful to desktop experience and general convenience. Some
  # of these may also be to specific server environments, too. Most of these
  # options reduce security to a certain degree.

  # Reenable multilib, may be useful to playing certain games.
  # nix-mineral.overrides.desktop.allow-multilib = true;

  # Reenable unprivileged userns. Although userns is the target of many
  # exploits, it also used in the Chromium sandbox, unprivileged containers,
  # and bubblewrap among many other applications.
  # nix-mineral.overrides.desktop.allow-unprivileged-userns = true;

  # Enable doas-sudo wrapper, useful for scripts that use "sudo." Installs
  # nano for rnano as a "safe" method of editing text as root.
  # Use this when replacing sudo with doas, see "Software Choice."
  # sudo = doas
  # doasedit/sudoedit = doas rnano
  # nix-mineral.overrides.desktop.doas-sudo-wrapper = true;

  # Allow executing binaries in /home. Highly relevant for games and other
  # programs executing in the /home folder.
  # nix-mineral.overrides.desktop.home-exec = true;

  # Allow executing binaries in /tmp. Certain applications may need to execute
  # in /tmp, Java being one example.
  # nix-mineral.overrides.desktop.tmp-exec = true;

  # Allow executing binaries in /var/lib. LXC, and system-wide Flatpaks are
  # among some examples of applications that requiring executing in /var/lib.
  # nix-mineral.overrides.desktop.var-lib-exec = true;

  # Allow all users to use nix, rather than just users of the "wheel" group.
  # May be useful for allowing a non-wheel user to, for example, use devshell.
  # nix-mineral.overrides.desktop.nix-allow-all-users = true;

  # Automatically allow all connected devices at boot in USBGuard. Note that
  # for laptop users, inbuilt speakers and bluetooth cards may be disabled
  # by USBGuard by default, so whitelisting them manually or enabling this
  # option may solve that.
  # nix-mineral.overrides.desktop.usbguard-allow-at-boot = true;

  # Enable USBGuard dbus daemon and add polkit rules to integrate USBGuard with
  # GNOME Shell. If you use GNOME, this means that USBGuard automatically
  # allows all newly connected devices while unlocked, and blacklists all
  # newly connected devices while locked. This is obviously very convenient,
  # and is similar behavior to handling USB as ChromeOS and GrapheneOS.
  # nix-mineral.overrides.desktop.usbguard-gnome-integration = true;

  # Completely disable USBGuard to avoid hassle with handling USB devices at
  # all.
  nix-mineral.overrides.desktop.disable-usbguard = true;

  # Rather than disable ptrace entirely, restrict ptrace so that parent
  # processes can ptrace descendants. May allow certain Linux game anticheats
  # to function.
  # nix-mineral.overrides.desktop.yama-relaxed = true;

  # Allow processes that can ptrace a process to read its process information.
  # Requires ptrace to even be allowed in the first place, see above option.
  # Note: While nix-mineral has made provisions to unbreak systemd, it is
  # not supported by upstream, and breakage may still occur:
  # https://github.com/systemd/systemd/issues/12955
  # nix-mineral.overrides.desktop.hideproc-relaxed = true;

  ## Performance
  # Options to revert some performance taxing tweaks by nix-mineral, at the cost
  # of security. In general, it's recommended not to use these unless your system
  # is otherwise unusable without tweaking these.

  # Allow symmetric multithreading and just use default CPU mitigations, to
  # potentially improve performance.
  nix-mineral.overrides.performance.allow-smt = true;

  # Disable all CPU mitigations. Do not use with the above option. May improve
  # performance further, but is even more dangerous!
  # nix-mineral.overrides.performance.no-mitigations = true;

  # Enable bypassing the IOMMU for direct memory access. Could increase I/O
  # performance on ARM64 systems, with risk. See URL: https://wiki.ubuntu.com/ARM64/performance
  # nix-mineral.overrides.performance.iommu-passthrough = true;

  # Page table isolation mitigates some KASLR bypasses and the Meltdown CPU
  # vulnerability. It may also tax performance, so this option disables it.
  # nix-mineral.overrides.perforamcne.no-pti = true;

  ## Security
  # Other security related options that were not enabled by default for one
  # reason or another.

  # Lock the root account. Requires another method of privilege escalation, i.e
  # sudo or doas, and declarative accounts to work properly.
  # nix-mineral.overrides.security.lock-root = true;

  # Reduce swappiness to bare minimum. May reduce risk of writing sensitive
  # information to disk, but hampers zram performance. Also useless if you do
  # not even use a swap file/partition, i.e zram only setup.
  # nix-mineral.overrides.security.minimum-swappiness = true;

  # Enable SAK (Secure Attention Key). SAK prevents keylogging, if used
  # correctly. See URL: https://madaidans-insecurities.github.io/guides/linux-hardening.html#accessing-root-securely
  # nix-mineral.overrides.security.sysrq-sak = true;

  # Privacy/security split.
  # This option disables TCP timestamps. By default, nix-mineral enables
  # tcp-timestamps. Disabling prevents leaking system time, enabling protects
  # against wrapped sequence numbers and improves performance.
  #
  # Read more about the issue here:
  # URL: (In favor of disabling): https://madaidans-insecurities.github.io/guides/linux-hardening.html#tcp-timestamps
  # URL: (In favor of enabling): https://access.redhat.com/sites/default/files/attachments/20150325_network_performance_tuning.pdf
  # nix-mineral.overrides.security.tcp-timestamp-disable = true;

  # Disable loading kernel modules (except those loaded at boot via kernel
  # commandline)
  # Very likely to cause breakage unless you can compile a list of every module
  # you need and add that to your boot parameters manually.
  # nix-mineral.overrides.security.disable-modules = true;

  # Disable TCP window scaling. May help mitigate TCP reset DoS attacks, but
  # may also harm network performance when at high latencies.
  # nix-mineral.overrides.security.disable-tcp-window-scaling = true;

  # Disable bluetooth entirely. nix-mineral borrows a privacy preserving
  # bluetooth configuration file by default, but if you never use bluetooth
  # at all, this can reduce attack surface further.
  # nix-mineral.overrides.security.disable-bluetooth = true;

  # Disable Intel ME related kernel modules. This is to avoid putting trust in
  # the highly privilege ME system, but there are potentially other
  # consequences.
  #
  # If you use an AMD system, you can enable this without negative consequence
  # and reduce attack surface.
  #
  # Intel users should read more about the issue at the below links:
  # https://www.kernel.org/doc/html/latest/driver-api/mei/mei.html
  # https://en.wikipedia.org/wiki/Intel_Management_Engine#Security_vulnerabilities
  # https://www.kicksecure.com/wiki/Out-of-band_Management_Technology#Intel_ME_Disabling_Disadvantages
  # https://github.com/Kicksecure/security-misc/pull/236#issuecomment-2229092813
  # https://github.com/Kicksecure/security-misc/issues/239
  #
  # nix-mineral.overrides.security.disable-intelme-kmodules = true;

  # DO NOT USE THIS OPTION ON ANY PRODUCTION SYSTEM! FOR TESTING PURPOSES ONLY!
  # Use hardened-malloc as default memory allocator for all processes.
  # nix-mineral.overrides.security.hardened-malloc = true;

  ## Software Choice
  # Options to add (or remove) opinionated software replacements by nix-mineral.

  # Replace sudo with doas. doas has a lower attack surface, but is less
  # audited.
  # nix-mineral.overrides.software-choice.doas-no-sudo = true;

  # Replace systemd-timesyncd with chrony, for NTS support and its seccomp
  # filter.
  # nix-mineral.overrides.software-choice.secure-chrony = true;

  # Use Linux Kernel with hardened patchset. Concurs a multitude of security
  # benefits, but prevents hibernation.*
  #
  # (No longer recommended as of July 25, 2024. The patchset being behind by
  # about a week or so is one thing, but the package as included in nixpkgs is
  # way too infrequently updated, being several weeks or even months behind.
  # Therefore, it is recommended to choose an LTS kernel like 5.15, 6.1, or 6.6
  # in your own system configuration.*)
  #
  # nix-mineral.overrides.software-choice.hardened-kernel = true;

  # Dont use the nix-mineral default firewall, if you wish to use alternate
  # applications for the same purpose.
  # nix-mineral.overrides.software-choice.no-firewall = true;
}
