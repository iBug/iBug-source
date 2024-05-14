---
title: "Migrating Ubuntu onto ZFS"
tags: linux server zfs
redirect_from: /p/68
toc: false
---

As part of a planned disk migration, I decided to move my Ubuntu installation from a traditional ext4 setup to ZFS.
I did a lot of preparation and research, but things went much smoother than I had previously anticipated.
I did not even have to consult IPMI for any recovery.

Existing partition layout:

```console
# fdisk -l /dev/nvme1n1
[...]
Device             Start        End    Sectors  Size Type
/dev/nvme1n1p1      2048    1050623    1048576  512M EFI System
/dev/nvme1n1p2   1050624  269486079  268435456  128G Linux filesystem
/dev/nvme1n1p3 269486080 3907029134 3637543055  1.7T Solaris /usr & Apple ZFS
```

Since I already have `/home` running on ZFS `pool0`, there's not much to prepare.
All I need to move is the rootfs itself, which has around 20 GB of data.

Start by installing anything necessary:

```shell
apt install zfs-initramfs arch-install-scripts
```

Then create the dataset layout:

```shell
# pool0 already has xattr=sa
zfs create \
  -o canmount=off \
  -o mountpoint=none \
  -o acltype=posix \
  pool0/ROOT
zfs create -o mountpoint=/mnt/new pool0/ROOT/ubuntu

rsync -avSHAXx --delete / /mnt/new/
```

Now there's a little deviation from common setup.
I don't trust GRUB's ZFS support, so I'm going to merge `/boot` into the EFI partition (which has a decent 512 MB of capacity).
This is a decision made after surveying my friends' setup.

```shell
# Merge data
rsync -ax /boot/ /boot/efi/ # Ignore any errors
umount /boot/efi
vim /etc/fstab
# Change /boot/efi to /boot
# Also remove the current rootfs entry
systemctl daemon-reload
mount /boot
```

Now prepare GRUB:

```shell
zpool set bootfs=pool0/ROOT/ubuntu pool0
mount -o bind /boot /mnt/new/boot
arch-chroot /mnt/new
```

```console
# grub-install
Installing for x86_64-efi platform.
grub-install: error: cannot find EFI directory.
```

Well, if only `grub-install` didn't hard-code `/boot/efi` (which is against the FHS standard anyways).
Fortunately, I recall a small detail that could make this work in another convenient way:

```shell
dpkg-reconfigure grub-efi-amd64
```

Also regenerate GRUB configuration:

```shell
zfs set mountpoint=/ pool0/ROOT/ubuntu
update-grub
```

Now double-check the GRUB configuration at `/boot/grub/grub.cfg` and make sure there are lines like this:

```text
linux /vmlinuz [...] root=ZFS=pool0/ROOT/ubuntu [...]
```

After verifying paths to the kernel and the initrd image are correct, reboot:

```shell
reboot
```

In just a minute, I noticed my server came back up.
Time to confirm everything is working as expected:

```console
# mount
pool0/ROOT/ubuntu on / type zfs (rw,relatime,xattr,posixacl,casesensitive)

# df -h /
Filesystem         Size  Used Avail Use% Mounted on
pool0/ROOT/ubuntu  1.2T   11G  1.1T   1% /

# zfs get compressratio pool0/ROOT
NAME        PROPERTY       VALUE  SOURCE
pool0/ROOT  compressratio  2.02x  -
```

The last thing is to rewrite my rootfs backup script to take snapshots directly, instead of rsync-ing to another ZFS pool before taking a snapshot there.
After taking a snapshot, I can also send it away as a "backup against disk failure".

A slightly revised version of my snapshotting script, sans the sending part:

```shell
#!/bin/sh

set -e

DATASET=pool0/ROOT/ubuntu
DATE=$(date +%Y%m%d)
SNAPSHOT="$DATASET@$DATE"
RETENTION_DAYS="${1:-7}"
RETENTION="$((RETENTION_DAYS * 86400))"

NOW="$(($(date +%s) - 3600))"
if [ "$(zfs list -Hpo name "$SNAPSHOT")" = "$SNAPSHOT" ]; then
  echo "Snapshot exists: $SNAPSHOT"
else
  zfs snapshot -ro ibug:retention="$RETENTION" "$SNAPSHOT"
fi

zfs list -Hpt snapshot -o name,creation,ibug:retention "$DATASET" |
  while read -r zNAME zCREATION zRETENTION; do
  if [ "$zRETENTION" = "-" ]; then
    # assume default value
    zRETENTION="$((7 * 86400))"
  fi
  UNTIL="$((zCREATION + zRETENTION))"
  UNTIL_DATE="$(date -d "@$UNTIL" "+%Y-%m-%d %H:%M:%S")"
  echo "$zNAME: $UNTIL_DATE"
  if [ "$NOW" -ge "$UNTIL" ]; then
    zfs destroy -rv "$zNAME"
  fi
done
```

```shell
# crontab
15 4 * * 1,5     /root/backup.sh 30
15 4 * * 0,2-4,6 /root/backup.sh  7
```
