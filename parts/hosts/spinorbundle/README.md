# spinorbundle

## Table of Contents

1. [About](1-about)
2. [Installation](2-installation)
3. [Troubleshooting](3-troubleshooting)
   1. [Root partition fails to be labeled](root-partition-fails-to-be-labeled)

## 1. About

Secondary windows (papa needs his occasional osu! grind) dualbooted laptop
running btrfs based opt-in filesystem.

TODO specs?

## 2. Installation

First things first, I can't read this tty crap

```bash
sudo su
setfont ter-132n
```

Much better, now set up a main root partition on `/dev/sdaX` and a swap
partition on `/dev/sdaY`

```bash
cgdisk /dev/sda
```

then encrypt the main partition using LUKS and open it

```bash
cryptsetup --verify-passphrase -v luksFormat /dev/sdaX
cryptsetup open /dev/sdaX enc
```

format the partitions and don't forget to **label them**!

```bash
mkswap -L swap /dev/sdaY
swapon /dev/disk/by-label/swap
mkfs.btrfs -L root /dev/mapper/enc
cryptsetup config /dev/sdX --label root_crypt
```

also if your win boot partition `/dev/sdaZ` is not labeled yet, go ahead and
label it

```bash
fatlabel /dev/sdaZ boot
```

Now we can proceed to create btrfs subvolumes. We'll be making a few of them

1. `/mnt/root`: main subvolume, flushed on every boot
2. `/mnt/nix`: subvolume holding `/nix/store` - easily reconstructible, but
   worth caching and thus will be persistent between boots
3. `/mnt/persist`: subvolume holding all of the needed permanent data and main
   mount point for [impermanence](https://github.com/nix-community/impermanence)
4. `/mnt/var/log`: low data priority, but worth preserving between boots due
   to possible error logs

_Note_: You may consider also having a `/mnt/home` subvolume preserved between
boots since it's easier to maintain, however, I decided to flush the `/home`
directory between boots as well and reconstruct it using `home-manager` so
I am omitting the `/mnt/home` subvolume parts.

```bash
mount -t btrfs /dev/mapper/enc /mnt
btrfs su cr /mnt/root
btrfs su cr /mnt/nix
btrfs su cr /mnt/persist
btrfs su cr /mnt/log

btrfs su snapshot -r /mnt/root /mnt/root-blank
umount /mnt
```

Now we proceed to mount all the previously created subvolumes, feel free
to modify the btrfs mountflags if needed but don't forget to patch
`hardware-configuration.nix` afterwards

```bash
mount -o noatime,compress=zstd,subvol=root /dev/mapper/enc /mnt

mkdir -p /mnt/{nix,persist,var/log,boot}
mount -o noatime,compress=zstd,subvol=nix /dev/mapper/enc /mnt/nix
mount -o noatime,compress=zstd,subvol=persist /dev/mapper/enc /mnt/persist
mount -o noatime,compress=zstd,subvol=log /dev/mapper/enc /mnt/var/log

mount /dev/disk/by-label/boot /mnt/boot
```

_Notenote_: At this stage you should either start an ssh-agent
(``eval `ssh-agent` ``) and add the
appropriate keys (`ssh-add /root/.ssh/id_ed25519`) or in case you don't want
to use agenix you should patch the config with your desired way of handling
secrets and default passwords.

Now we can proceed to install the desired `nixosConfiguration` of our flake.

```bash
nix-shell -p git nixFlakes pywal
export USER="my_user"
export HOST="spinorbundle"

mkdir -p /mnt/{tmp,persist/etc,persist/home/$USER/.cache}
git clone https://github.com/tsandrini/tensorfiles /mnt/persist/etc/tensorfiles
cd /mnt/etc/tensorfiles/nix

# in case you have made any changes to the flake don't forget to add them
# to the git staged cache
# git add *

# the whole setup builds on pywal and its colorscheme generation so we have to
# generate some initial structure and copy it to a persistenst storage
# otherwise xinit & startx and the whole X server won't work properly
wal -i var/example-wallpaper.png
cp -r /root/.cache/wal /persist/home/$USER/.cache/

TMPDIR="/mnt/tmp" USER=$USER nixos-install --root /mnt --flake .#$HOST
```

now you should be ready to go and pray!

```bas
reboot # hehe
```

## 3. Troubleshooting

### Root partition fails to be labeled

First try

```bash
btrfs filesystem label /mnt root
```

if `btrfs filesystem show /dev/mapper/enc` is correctly outputting the label
while `lsblk -f` not run the following command

```bash
udevadm trigger
```

beware that in some cases this might update the partition tables even of your
live installation drive resulting in a bunch of `SQUASHFS ERROR` in which
case the fastest solution would be to just try again with a freshly flashed
drive (or you can fix it manually via `wipefs` of course).
