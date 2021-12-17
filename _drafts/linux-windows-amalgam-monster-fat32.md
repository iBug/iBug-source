---
title: "New Pandora's box Part II: Install Linux and Windows onto the same FAT32 partition"
tags: linux windows
redirect_from: /p/48
header:
  overlay_image: /image/header/art-1.jpg
  overlay_filter: 0.1
---

In [my previous article]({% post_url 2021/2021-11-28-linux-windows-amalgam-monster-ntfs %}), I shared my experience of installing Windows 10 and Arch Linux onto the same partition formatted as NTFS. Before Linux 5.15, the only mutual filesystem between Linux and Windows is the FAT family. That brought me another interesting question, whether it's possible to do the same again on FAT32.

To put it in a nutshell, [it *IS* possible][reddit] but only after struggling through a truckload of hassles.

## Background research

Before putting this crap into action, it's necessary to determine the feasibility of the idea. The first thing to come to mind is that FAT32 lacks virtually everything you need for a normal Linux system, such as POSIX permission system (owner and mode), special files like symbolic links, sockets etc. In fact, an attempt to `pacstrap` onto a FAT32 filesystem errors at virtually every step for failing to create some files.

It wouldn't take long before landing on [this Super User question][su-comment] when searching around for "installing Linux in FAT32".


  [reddit]: https://www.reddit.com/r/archlinux/comments/r0k4ye/arch_windows_xp_on_the_same_fat32_partition/
  [a]: https://bbs.archlinux.org/viewtopic.php?id=173748
  [su-comment]: https://superuser.com/posts/comments/2349156
  