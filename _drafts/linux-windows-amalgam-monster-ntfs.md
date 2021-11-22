---
title: "New Pandora's box: Install Linux and Windows onto the same partition"
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

## Starting off

At the time of writing this article, the latest Arch Linux ISO was shipped with Kernel 5.14.15 - no new NTFS3 driver. I need to create one for myself or this won't work.

[Archiso][archiso] is Arch's official tool for creating custom ISO images. I'm not normally an Arch user, so I choose to install Arch first from an official ISO (20211101).

![Partitioning in Arch ISO](/image/linux/monster/install-arch-partition.png)

After this temporary system is set up, I just follow the archiso guide and receive my own `archlinux-2021.11.22-x86_64.iso` with no trouble. It has Kernel 5.15.4 packed.

I copy the ISO onto the Proxmox VE host system, restart with this new ISO and wipe `/dev/sda2` to avoid (possible) further issues with the Windows installer

```shell
fdisk -l /dev/sda  # confirm partition layout
mount -t ntfs3 /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
pacstrap /mnt base linux linux-firmware
```


  [archiso]: https://wiki.archlinux.org/title/archiso
  [ntfs3]: https://www.techrepublic.com/article/linux-kernel-5-15-is-now-available-and-it-has-something-special-for-ntfs-users/
  [ntfs-3g]: https://en.wikipedia.org/wiki/NTFS-3G
