---
title: "New Pandora's box: Install Linux and Windows onto the same NTFS partition"
tags: linux windows
redirect_from: /p/47

published: false
---

Linux 5.15 is shipped with a brand new driver for Microsoft's classic NTFS filesystem, [NTFS3][ntfs3]. Unlike the decades-old open-source NTFS-3G project, which is based on FUSE and have always received criticism for breaking existing filesystems, NTFS3 is a new driver that is designed to be compatible with contemporary NTFS filesystems, while providing safer read/write operations. This makes it possible to install Linux onto NTFS (as is with most other filesystems), and opens up a whole new can of worms: run Linux alongside Windows, **TOGETHER**.

<div class="notice--danger" markdown="1">
#### <i class="fas fa-exclamation-triangle"></i> WARNING
{: .no_toc }

This is COMPLETELY EXPERIMENTAL. If you are not familiar with either Linux or Windows, **do not try this**.
</div>

Sounds WEIRD to me. I'm going to do this experiment on my Proxmox VE cluster.

![Create virtual machine](/image/linux/monster/vm-create.png)

## Preparation

### Archiso

At the time of writing this article, the latest Arch Linux ISO (2021.11.01) was shipped with Kernel **5.14**.15 - no new NTFS3 driver. I need to create one for myself or this won't work.

[Archiso][archiso] is Arch's official tool for creating custom ISO images. I'm not normally an Arch user, so I choose to install Arch first from an official ISO (20211101) before wiping it.

![Partitioning in Arch ISO](/image/linux/monster/install-arch-partition.png)

After this temporary system is set up, I just follow the Archiso guide and receive my own `archlinux-2021.11.22-x86_64.iso` with no trouble. It has Kernel **5.15**.4 packed.

I copy the ISO onto the Proxmox VE host system, reboot the VM with this new ISO and wipe `/dev/sda2` to avoid (possible) further issues with the Windows installer. I also format `/dev/sda1` again to ensure I'm really starting over anew.

### Install Windows

Since NTFS is developed by Microsoft and for Windows, it seems reasonable to assume Windows is best suited for NTFS. So I'll install Windows first lest it recognizes the filesystem created by `mkfs.ntfs` (from the old `ntfs-3g` package) as "foreign" and complains anyhow.

The installation process of Windows 10 has always been as boring and mundane as it is, so I'm not going to be verbose here. Following the usual steps, except that the disk has already been partitioned, it's easy to get Windows 10 up and ready.

![Windows 10 OOBE screen](/image/linux/monster/install-win10-oobe.png)

Proceeding through the out-of-box experience and I get to the desktop. There's not many things of interest here, so I just shutdown the VM and take a snapshot.

Now it's time to get this compound monstrosity set up.

## The Main Show

Swap the CD/DVD drive image for the newly created archiso and boot it up:

![CD/DVD image selection](/image/linux/monster/install-archiso.png)

With the proper Linux kernel equipped, I can now mount the NTFS partition create by Windows installer. It seems NTFS is sophisticated enough to even allow Unix filesystem attibutes, like file modes (permissions) and ownership, as well as "special file types" like symbolic links and named sockets (Unix domain sockets). This may hint that bootstrapping a Linux system should not be too problematic.

```shell
fdisk -l /dev/sda  # confirm partition layout
mount -t ntfs3 /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
pacstrap /mnt base linux linux-firmware
```

Indeed, `pacstrap` goes so smoothly that I almost forget it's on a non-native filesystem. The only thing that makes me concerned is that **there's no `fsck` tool for NTFS**.

![pacstrap output](/image/linux/monster/install-arch-pacstrap.png)

Now I can chroot into the system and set up the rest of the system.

```shell
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
vim /etc/locale.gen  # add en_US.UTF-8 UTF-8
echo monster > /etc/hostname
passwd -d root
exit  # quit chroot environment, return to archiso
```

Fixing the bootloader is a bit different than usual, as Linux detects NTFS partitions as `ntfs`, not `ntfs3`. In case of auto mounting, Linux will try to mount with `-t ntfs`, which is not available (it's provided by ntfs-3g). Fortunately, there's a `rootfstype=` [kernel command-line parameter][cmdline] to manually specify the "filesystem type" parameter when mounting.

Putting this into action:

```shell
arch-chroot /mnt
# configure networking
pacman -Sy grub efibootmgr
vim /etc/default/grub
# remove "quiet" from GRUB_CMDLINE_LINUX
# set GRUB_CMDLINE_LINUX_DEFAULT="rootfstype=ntfs3"
grub-install
grub-mkconfig -o /boot/grub/grub.cfg
exit
```

![Install GRUB for Arch Linux](/image/linux/monster/install-arch-grub.png)

To make things a bit more interesting, I'm adding a desktop environment:

```shell
pacstrap /mnt gnome
```

And configure networking as well:

```shell
cd /mnt/etc/systemd/network
vim ens18.network
cd ../system
ln -s /lib/systemd/system/systemd-networkd.service multi-user.target.wants/
```

All set, let's give it a try.

## Arch Linux with Windows 10 usage experience {#usage-experience}

Arch Linux plays surprisingly well with the new NTFS3 filesystem driver.

![System information in Arch Linux](/image/linux/monster/after-arch-neofetch.png)

## Links & Credits

- Pioneer from r/archlinux: [Arch Linux on NTFS3!](https://www.reddit.com/r/archlinux/comments/qwsftq/arch_linux_on_ntfs3/)
- Original idea by a GitHub user: [Installing Windows and Linux into the same partition](https://gist.github.com/motorailgun/cc2c573f253d0893f429a165b5f851ee)


  [archiso]: https://wiki.archlinux.org/title/archiso
  [cmdline]: https://wiki.archlinux.org/title/kernel_parameters
  [ntfs3]: https://www.techrepublic.com/article/linux-kernel-5-15-is-now-available-and-it-has-something-special-for-ntfs-users/
  [ntfs-3g]: https://en.wikipedia.org/wiki/NTFS-3G
