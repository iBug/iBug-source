---
title: "Install Proxmox VE on eMMC"
categories: tech
tags: linux server proxmox-ve
header:
  teaser: /image/proxmox.jpg
redirect_from: /p/49
---

Recently I bought a mini PC looking forward to setting up a home router. It started quite well except the specs were higher than I anticipated. 8 GB RAM plus 128 GB eMMC - too much waste for "just a router", so I figured I'd get some virtual machines to improve its utilization. Choosing the virtualization platform isn't hard - I'm most familiar with Proxmox VE.

The offcial ISO installer is pretty straightforward, until the last step:

```text
Unable to get device for partition 1 on device /dev/mmcblk0
```

## Solution

The Proxmox VE forum is *completely unhelpful* this time ([1][1], [2][2]) with staff keeping on saying "it's not supported", so I had to look around for alternatives. Fortunately this article is right there:

- [解决 Proxmox VE 无法安装到 eMMC 上的问题 - lookas2001](https://lookas2001.com/%E8%A7%A3%E5%86%B3-proxmox-ve-%E6%97%A0%E6%B3%95%E5%AE%89%E8%A3%85%E5%88%B0-emmc-%E4%B8%8A%E7%9A%84%E9%97%AE%E9%A2%98/)

Turns out it's hard-coded into Proxmox VE's Perl installer script, so all you have to do is to patch it:

1. Boot the installer ISO to the first menu, select the second option `Install Proxmox VE (Debug mode)`
2. The first time you're present with a command-line prompt, type `exit` and Enter to skip it. This is a very early stage and you can't do much here.
3. The second time you have a shell, locate `/usr/bin/proxinstall` and open it. Text editors such as `vi` and `nano` are available.

   <div class="notice notice--primary" markdown="1">
     **For Proxmox VE 8 installer**, the file you're going for is `/usr/share/perl5/Proxmox/Sys/Block.pm`.
   </div>

4. Search for `unable to get device` and you should find some code like this:

    ```perl
    } elsif ($dev =~ m|^/dev/[^/]+/hd[a-z]$|) {
        return "${dev}$partnum";
    } elsif ($dev =~ m|^/dev/nvme\d+n\d+$|) {
        return "${dev}p$partnum";
    } else {
        die "unable to get device for partition $partnum on device $dev\n";
    }
    ```

    The full code can be found [on GitHub](https://github.com/proxmox/pve-installer/blob/b04864ece2654c6ecf794f9c3ad1cedede351532/proxinstall#L729) if you'd like.

5. See how different kinds of storage devices are enumerated? Now add `/dev/mmcblk` to the list like this:

    ```perl
    } elsif ($dev =~ m|^/dev/[^/]+/hd[a-z]$|) {
        return "${dev}$partnum";
    } elsif ($dev =~ m|^/dev/nvme\d+n\d+$|) {
        return "${dev}p$partnum";
    } elsif ($dev =~ m|^/dev/mmcblk\d+$|) {
        return "${dev}p$partnum";
    } else {
        die "unable to get device for partition $partnum on device $dev\n";
    }
    ```

6. Save your edits and type `exit`. Proceed with the installation as normal. Select `/dev/mmcblk0` (without the `bootX` suffix) as the install target. You may want to disable swap to avoid rapid wearing of the eMMC.
7. The next time you have a shell, use `exit` to skip it. Nothing to do here.

## Rambling

While it's possible to install Proxmox VE on top of a matching version of Debian, it's tedious to install Debian *just for PVE*. The last time I had to do it this way was on very old hardware that the PVE installer just crashed (X server died), and that the PVE installer didn't have a CLI version. Plus a standard Debian installation typically comes with extra stuff that you don't want on a PVE system (or want to get rid of ASAP).

It's also possible to modify the installer script beforehand, but you need to unpack `pve-installer.squashfs` and re-pack it into the ISO. You should think more seriously if you want to install PVE on a lot of eMMC devices.


  [1]: https://forum.proxmox.com/threads/unable-to-get-device-for-partition-1-on-device-dev-mmcblk0.42348/
  [2]: https://forum.proxmox.com/threads/unable-to-get-device-for-partition-1.43234/
