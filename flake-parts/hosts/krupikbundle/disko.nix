# --- flake-parts/hosts/krupikbundle/disko.nix
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
# Kingston KC3000 2 TB, serial 50026B7384558F7F (the factory-empty one; its twin
# ...8F7D still carries the previous Debian + radar data). Addressed by id: the
# nvme0/nvme1 numbering swapped between two boots of this box.
#
# GPT, 1 GiB ESP, LUKS2 ("enc") over the rest with ext4 root inside. Swap is a
# swapfile on the encrypted root (see hardware-configuration.nix), so a single
# passphrase unlocks everything.
#
# Install (from the vila LAN; the kexec installer takes a NEW DHCP lease, so
# resume with --target-host <new ip> --phases disko,install,reboot if needed):
#   nixos-anywhere --flake .#krupikbundle --target-host root@<ip> \
#     --disk-encryption-keys /tmp/krupik-luks.key <local file> \
#     --extra-files <dir with etc/ssh/ssh_host_ed25519_key{,.pub},
#                    etc/secrets/initrd/ssh_host_ed25519_key,
#                    home/tsandrini/.ssh/id_ed25519{,.pub}> \
#     --chown /home/tsandrini/.ssh 1001:100
# (key file content = passphrase, NO trailing newline; keys live in keys/).
{
  disko.devices = {
    disk = {
      nvme-main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SKC3000D2048G_50026B7384558F7F";
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
                passwordFile = "/tmp/krupik-luks.key";
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
