# --- flake-parts/hosts/navibundle/disko.nix
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
#
# Kingston Fury Renegade G5 2 TB (nvme0n1): GPT, 1 GiB ESP, LUKS2 ("enc") over
# the rest with ext4 root inside. Swap is a swapfile on the encrypted root
# (see hardware-configuration.nix), so a single passphrase unlocks everything.
#
# Install: nixos-anywhere --disk-encryption-keys /tmp/navi-luks.key <local file>
# (file content = passphrase, NO trailing newline).
{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SFYR2S2T0_50026B7283C4AABF";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "enc";
                passwordFile = "/tmp/navi-luks.key";
                # NOTE: TRIM through dm-crypt for the SSD (services.fstrim)
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
