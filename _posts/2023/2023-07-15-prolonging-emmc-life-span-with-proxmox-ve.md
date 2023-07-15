---
title: "Prolonging eMMC Life Span with Proxmox VE"
tags: linux server proxmox-ve
redirect_from: /p/58
header:
  teaser: /image/proxmox.jpg
---

Since my blog on [installing Proxmox VE on eMMC](/p/49), there's been a lot of discussion over the Internet on this. I suspect that Proxmox decided not to include eMMCs in their hardware options by design, as eMMCs typically do not offer the same level of performance as anything better than USB flash drives. Among many concerns, the most important one is the limited number of write cycles that an eMMC can sustain, while Proxmox VE, being an enterprise-grade product, has to constantly write stuff like logs to the storage. I came across [this blog (fat-nerds.com)][src] on reducing eMMC writes on a Proxmox VE installation on a single-board computer from a Hong Kong guy, so I figure I'd share my ideas here.

  [src]: https://fat-nerds.com/dot-nerd/cut-down-proxmox-ve-emmc-sd-read-write/

This article will be a remix of the original blog, with some of my own experiences blended in.

As a courtesy, here's the disclaimer from the original blog:

> 警告：下面的設定不應該被應用於有重大價值的伺服器上面！這只是筆者強行在便宜硬件上塞進PVE並以更暴力的方式去為其續命的手段。

> WARNING: The following settings should not be applied to production servers! This is just a method for the author to force Proxmox VE onto cheap hardware and to prolong its life span.

## Disable swap {#swap}

Swap is the mechanism of offloading some memory from physical RAM to disk in order to improve RAM management efficiency. If you have a lot of physical RAM, chances are swap isn't going to be much helpful while producing a lot of writes to the disk. On a default Proxmox VE installation, the swap size is set from 4 GB to 8 GB, depending on your RAM capacity and disk size.

You can temporarily disable swap by setting sysctl `vm.swappiness` to 0:

```shell
sysctl vm.swappiness=0
```

Or why not just remove the swap space altogether?

```shell
swapoff -a  # disables swap
vim /etc/fstab  # remove the swap entry
lvremove /dev/pve/swap  # remove the swap logical volume
```

In most cases, you won't need swap on a Proxmox VE host. If you find yourself needing swap, you should probably consider upgrading your RAM instead.

## System logs {#logs}

### Move logs to another disk {#move-logs}

Every system produces logs, but Proxmox VE is particularly prolific on this. In a production environment, you'll want to keep the logs by storing them on a separate disk (but why is it running on an eMMC in the first place?). So get another reliable disk and migrate the logs:

```shell
# assuming the new disk is /dev/sdX
systemctl stop rsyslog

mount /dev/sdX1 /var/log1
rsync -avAXx /var/log/ /var/log1/
rm -rf /var/log
mkdir /var/log
umount /var/log1
vim /etc/fstab  # add an entry for /dev/sdX1
systemctl daemon-reload  # see notes
mount /var/log

systemctl start rsyslog
```

Notes on the above commands:

- Rsync is better than `cp` if you need to perform a non-trivial copy operation. (The original blog uses `cp`.)
- Using `fstab` guarantees any mounts are consistent and persistent across reboots.
- Why `systemctl daemon-reload` after edting `fstab`? Because [systemd is sometimes too smart][systemd-umount] (I got bitten by this once).

  [systemd-umount]: https://unix.stackexchange.com/q/474743/211239

### Or disable logs altogether {#disable-logs}

On a hobbyist setup, you may be fine with disabling logs altogether.

The original blog suggests replacing a few file with symlinks to `/dev/null`, which I find rather incomplete and ineffective. On my 5-GB-used rootfs, `/var/log` takes 1.8 GB, of which `/var/log/journal` eats 1.6 GB alone, so systemd journal is the first thing to go. Editing `/etc/systemd/journald.conf` and setting `Storage=none` will stop its disk hogging, but better yet, you can keep a minimal amount of logs by combining `Storage=volatile` and `RuntimeMaxUse=16M` ([ref][journald-volatile]).

  [journald-volatile]: https://unix.stackexchange.com/a/705057/211239

If you're on Proxmox VE 8+, you can create an "override" file for systemd-journald by adding your customizations to `/etc/systemd/journald.conf.d/override.conf`. This will save some trouble when the stock configuration file gets updated and you're asked to merge the changes.

For other logs, you can simple replace them with symlinks to `/dev/null`. For example:

```shell
ln -sfn /dev/null /var/log/lastlog
```

I'm not keen on this method as other logs only comes at a rate of a few hundred MBs per week, so I'd rather keep them around.

## Stop certain PVE services {#pve-services}

The original blog suggests stopping a few non-essential services as they (which I couldn't verify, nor do I believe so):

- High-Availability-related services (you don't need HA on a single-node setup):
  - `pve-ha-lrm`
  - `pve-ha-crm`
- Firewall logger: `pvefw-logger`
- Non-essential and non-PVE services:
  - spiceproxy (required for SPICE console, but noVNC is better)
  - corosync (required for multi-node setup)

Except for `pvefw-logger`, stopping these services will not save you much disk writes as per my experiences.

## Reduce `rrdcached` writes {#rrdcached}

`rrdcached` is the service that stores and provides data for the PVE web interface to display graphs on system resource usage. I have no idea how much writes it produces, so I just relay the optimization given in the original blog.

- Edit `/etc/default/rrdcached`:
  - Set `WRITE_TIMEOUT=3600` so it only writes to disk once per hour.
  - Comment out `JOURNAL_PATH` so it stops writing journals (not the data itself).
  - Add `FLUSH_TIMEOUT=7200` (timeout for `flush` command, not sure how useful it is).
- Edit `/etc/init.d/rrdcached` for it to pick up the new `FLUSH_TIMEOUT` value:
  
  Find these lines:

  ```shell
  ${WRITE_TIMEOUT:+-w ${WRITE_TIMEOUT}} \
  ${WRITE_JITTER:+-z ${WRITE_JITTER}} \
  ```

  And insert one line for `FLUSH_TIMEOUT`:

  ```shell
  ${WRITE_TIMEOUT:+-w ${WRITE_TIMEOUT}} \
  ${FLUSH_TIMEOUT:+-f ${FLUSH_TIMEOUT}} \
  ${WRITE_JITTER:+-z ${WRITE_JITTER}} \
  ```

After editing both files, restart the service: `systemctl restart rrdcached.service`

## Stop `pvestatd` {#pvestatd}

`pvestatd` provides an interface for hardware information for the PVE system. It shouldn't produce much writes and stopping it will prevent creation of new VMs and containers, so I don't recommend stopping it. The original blog probably included this option as a result of a mistake or ignorance.

## Conclusion

We can see how Proxmox VE is designed to provide enterprise-grade reliability and durability, at the expense of producing lots of disk writes for its various components like system logging and statistics. Based on the above analysis, it seems perfectly reasonable that Proxmox VE decides not to support eMMC storage.

This blog combines a few tips from the original blog and my own experiences. I hope it helps you with your Proxmox VE setup on any eMMC-backed devices.

<div class="notice notice--primary" markdown="1">
But *really*?
{: .align-center style="font-size: 1.6em;" }
</div>

## Results
{: .no_toc}

There's one key question left unanswered by everything above: How much writes does Proxmox VE really produce?

To answer this question, let's see some of my examples:

### Server 1
{: .no_toc}

Specs:

- Two enterprise-grade SSDs in RAID 1
- Running since October 2019
- "Master" node in a multi-node cluster, with the entire cluster running over 2,000 VMs and containers (~10 on this host)

Total writes as of July 2023 (rootfs-only, thanks to [this answer][ext4-lifetime-writes]):

  [ext4-lifetime-writes]: https://unix.stackexchange.com/q/121699/211239

```shell
# lrwxrwxrwx 1 root root 7 Jul 12 15:48 /dev/pve/root -> ../dm-4
# cat /sys/fs/ext4/dm-4/lifetime_write_kbytes
17017268104
```

Result: 4.5 TB annually.

### Server 2
{: .no_toc}

Specs:

- Two ol' rusty spinning drives in RAID 1
- Running since January 2022
- Belongs to a multi-node cluster, running around 20 VMs (~3 on this host)

Total writes as of July 2023 (rootfs-only):

```shell
# lrwxrwxrwx 1 root root 7 Jan 21  2022 /dev/pve/root -> ../dm-1
# cat /sys/fs/ext4/dm-1/lifetime_write_kbytes
2336580629
```

Result: 1.5 TB annually.

### Server 3
{: .no_toc}

Specs:

- Lab's storage server, single SSD for rootfs and ZFS SLOG (ZIL)
- Running since October 2022
- Single-node setup, running 2 VMs
- Data is stored separately

Total writes as of July 2023:

```shell
# smartctl -A /dev/sda
241 Total_LBAs_Written 2849895751
```

`humanize.naturalsize(2849895751 * 512, format="%.2f")`: 1.46 TB (≈ 2 TB annually)

### eMMC Write Life
{: .no_toc}

This one really depends on the hardware you get. In 2023 virtually every reasonable TLC flash chip should withstand at least 1,000 P/E cycles, so even a pathetic 8 GB eMMC should last around 10 TB of writes, [as that on a Raspberry Pi Compute Module 4][emmc-tbw].

  [emmc-tbw]: https://forums.raspberrypi.com/viewtopic.php?t=291808

If you get anything larger than that, you should be fine expecting it to survive at least 20 TB of writes.

## REAL Conclusion
{: .no_toc}

Congratulations on reading this far.

If you managed to hold your paranoia and refrain from putting anything into action, you can now sit back and relax. Unless you're squeezing hundreds of VMs and containers into a single eMMC-driven board (poor board) without separate storage for VMs, your eMMC is not going to die anytime soon.

## References

- Original blog (Traditional Chinese): [單板小主機上的Proxmox VE實務：暴力減少eMMC或SD卡的讀寫耗損][src]
- [CM4 eMMC durability - Terabytes written value (TBW)?][emmc-tbw]
