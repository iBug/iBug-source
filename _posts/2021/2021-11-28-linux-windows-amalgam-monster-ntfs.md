---
title: "New Pandora's box: Install Linux and Windows onto the same NTFS partition"
tags: linux windows
redirect_from: /p/47
header:
  overlay_image: /image/header/art-1.jpg
  overlay_filter: 0.1
---

Linux 5.15 is shipped with a brand new driver for Microsoft's classic NTFS filesystem, [NTFS3][ntfs3]. Unlike the decades-old open-source NTFS-3G project, which is based on FUSE and have always received criticism for breaking existing filesystems, NTFS3 is a new driver that is designed to be compatible with contemporary NTFS filesystems, while providing safer read/write operations. This makes it possible to install Linux onto NTFS (as is with most other filesystems), and opens up a whole new can of worms: run Linux alongside Windows, TOGETHER.

<div class="notice--danger" markdown="1">
#### <i class="fas fa-exclamation-triangle"></i> WARNING
{: .no_toc }

This is COMPLETELY EXPERIMENTAL. If you are not familiar with either Linux or Windows, **do not try this**.
</div>

Sounds WEIRD to me. I'm going to do this experiment on my Proxmox VE cluster.

![Create virtual machine](/image/linux/monster/vm-create.png){: .border }

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

Indeed, `pacstrap` goes so smoothly that I almost forget it's on a non-native filesystem. The only thing that makes me concerned is that **there's no `fsck` tool for NTFS** (*file not found: `fsck.ntfs3`* in console output).

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

Fixing the bootloader is a bit different than usual, as Linux detects NTFS partitions as `ntfs`, not `ntfs3`. In case of auto mounting, Linux will try to mount with `-t ntfs`, which is not available (it's provided by ntfs-3g). Fortunately, there's a `rootfstype=` [kernel command-line parameter][cmdline] to override the "filesystem type" parameter when mounting.

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
```

![Install GRUB for Arch Linux](/image/linux/monster/install-arch-grub.png)

To make things a bit more interesting, I'm adding a desktop environment:

```shell
pacman -Sy gnome
# select some items - not everything
```

And configure networking as well:

```shell
cd /etc/systemd/network
vim ens18.network
cd ../system
ln -s /lib/systemd/system/systemd-networkd.service multi-user.target.wants/
```

All set, let's give it a try.

## Arch Linux with Windows 10 usage experience {#usage-experience}

Arch Linux plays surprisingly well with the new NTFS3 filesystem driver.

![System information in Arch Linux](/image/linux/monster/after-arch-neofetch.png)

To keep things simple, I didn't install too much software. During my testing, the only issue I encountered was that `ldconfig` never worked. It always aborts.

![ldconfig stops working](/image/linux/monster/arch-terminal-sigabrt.png)

A non-issue is that there's no working `fsck` tool, and there's a systemd service "Fsck at boot" that consequently fails. It's not as useful so I just disabled it.

## Thoughts

I must admit I'm amazed at how exquisitely NTFS is designed. It's so mature that it hasn't even been updated [since Windows XP][ntfs-versions]. One important part of NTFS is its Extended Attributes (EA) for files. Every NTFS filesystem contains a special file named `$MFT` located under its root directory. This is the metadata for all files, including file names, "normal attributes" and ACL, among which is the EA. Every file has an associated EA entry, which can contain an arbitrary number of attributes (key-value pairs). In fact, the first generation of Windows Subsystem for Linux (WSL) stores Linux file modes and permissions [using custom EA keys][wsl-file], which gets adapted by the new NTFS3 driver. Other EA keys are also used as needed, like `security.capability`, which is a 20-byte bitset.

The new NTFS3 driver is a delighting improvement to the Linux ecosystem. Complaints about the classic NTFS-3G driver [have][1] [always][2] [been][3] [around][4]. Performance was one of the primary concerns because it not only is based on FUSE (Filesystem in USErspace), but also badly optimized. Use of FUSE means extra context switches when accessing files, which, paired with hard-coded 4 KiB read/write unit, delivers unusually slow access speeds.

While the NTFS3 driver is a bit more optimized, concerns around compatibility are still around. This is mainly because it's still built on knowledge obtained from reverse engineering than technical documentation and standard. Fortunately, stability for NTFS-3G is already at a satisfactory level, and the new driver is thought to be more reliable than the old one.

Besides, this is a perfect example of Linux's inclusiveness. Years before the commencement of the new NTFS3 driver, [attempts were made][ntfs-3g-rootfs] to run Linux on top of NTFS using NTFS-3G. This leads to an interesting question: Will Linux run on top of FAT32? Technical difficulties are more conspicuous and crutial this time, like lack of support and extensibility for file modes and more. I'll explore into this challenge and share my findings in a subsequent blog post. Stay tuned!

## Links & Credits

- Pioneer from r/archlinux: [Arch Linux on NTFS3!](https://www.reddit.com/r/archlinux/comments/qwsftq/arch_linux_on_ntfs3/)
- Original idea by a GitHub user: [Installing Windows and Linux into the same partition](https://gist.github.com/motorailgun/cc2c573f253d0893f429a165b5f851ee)


  [archiso]: https://wiki.archlinux.org/title/archiso
  [cmdline]: https://wiki.archlinux.org/title/kernel_parameters
  [ntfs3]: https://www.techrepublic.com/article/linux-kernel-5-15-is-now-available-and-it-has-something-special-for-ntfs-users/
  [ntfs-3g]: https://en.wikipedia.org/wiki/NTFS-3G
  [ntfs-3g-rootfs]: https://github.com/CyanoHao/NTFS-as-rootfs
  [ntfs-versions]: https://en.wikipedia.org/wiki/NTFS#Versions
  [wsl-file]: https://docs.microsoft.com/en-us/windows/wsl/file-permissions

  [1]: https://superuser.com/q/613869/688600
  [2]: https://www.reddit.com/r/linuxquestions/comments/73v5pi/why_is_ntfs_on_linux_so_slow/
  [3]: https://askubuntu.com/q/187813/612877
  [4]: https://unix.stackexchange.com/q/107978/211239
