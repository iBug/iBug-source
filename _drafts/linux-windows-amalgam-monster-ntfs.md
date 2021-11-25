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

Proceeding through the out-of-box experience and I get to the desktop. There's not many things of interest here, so I


```shell
fdisk -l /dev/sda  # confirm partition layout
mount -t ntfs3 /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
pacstrap /mnt base linux linux-firmware
```

## Links & Credits

- Pioneer from r/archlinux: [Arch Linux on NTFS3!](https://www.reddit.com/r/archlinux/comments/qwsftq/arch_linux_on_ntfs3/)
- Original idea published on GitHub Gist: [Installing Windows and Linux into the same partition](https://gist.github.com/motorailgun/cc2c573f253d0893f429a165b5f851ee)


  [archiso]: https://wiki.archlinux.org/title/archiso
  [ntfs3]: https://www.techrepublic.com/article/linux-kernel-5-15-is-now-available-and-it-has-something-special-for-ntfs-users/
  [ntfs-3g]: https://en.wikipedia.org/wiki/NTFS-3G
