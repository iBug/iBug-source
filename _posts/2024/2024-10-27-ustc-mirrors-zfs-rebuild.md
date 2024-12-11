---
title: Beating $3k SSD with $2k HDD?
tagline: Practical ZFS application on USTC Mirrors
tags: linux server zfs
redirect_from: /p/74
header:
  actions:
    - label: '<i class="fas fa-presentation-screen"></i> View slides'
      url: /p/72
---

A.K.A. Practical ZFS application on USTC Mirrors. A writeup of the talk I gave at Nanjing University this August.

{% assign image_base = "https://image.ibugone.com" %}

## Background

[USTC Open-Source Software Mirrors](https://mirrors.ustc.edu.cn/) is one of the largest public mirror sites in China. In the two months of May and June 2024, we served an average daily egress traffic of some 36 TiB, which breaks down as follows:

- 19 TiB from HTTP/HTTPS, among 17M requests
- 10.3 TiB from rsync, among 21.8k requests (if we count one absurd client in, the number of requests goes to 147.8k)

Over the years, as mirror repositories have grown and new repositories have been added, we have been running tight on disk space. For our two servers responsible for the mirror service, we have reached unhealthy levels of disk usage:

- HTTP server (XFS): 63.3 TiB used out of 66.0 TiB (96%, achieved on December 18, 2023)
- Rsync server (ZFS): 42.4 TiB used out of 43.2 TiB (98%, achieved on November 21, 2023)

The servers have the following configurations:

<dl>
<dt>HTTP server</dt>
<dd markdown="1">
- Set up in Fall 2020
- Intel Cascade Lake CPU, 256 GB DDR4 RAM
- Twelve 10 TB HDDs + One 2 TB SSD
- XFS on LVM on hardware RAID
- Reserved free PEs on LVM VG level as XFS cannot be shrunk
</dd>

<dt>Rsync server</dt>
<dd markdown="1">
- Set up in Winter 2016
- Intel Broadwell CPU, 256 GB DDR4 RAM
- Twelve 6 TB HDDs + some smaller SSDs for OS and cache
- RAID-Z3 on ZFS, 8 data disks + 3 parity disks + 1 hot spare
- All default parameters (except `zfs_arc_max`)
</dd>
</dl>

These servers are constantly running at an I/O utilization of over 90%, which results in less than 50 MB/s download speed even from within USTC campus. Clearly this is not the ideal performance for this kind of dedicated storage servers.

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors-io-utilization-may-2024.png"
  popup=true
  alt="I/O load of two servers from USTC Mirrors in May 2024"
  caption="I/O load of two servers from USTC Mirrors in May 2024" %}

## ZFS

ZFS is usually known for being the ultimate single-node storage solution. It combines RAID, volume management, and filesystem in one, and provides advanced features like snapshots, clones and send/receive. Everything in ZFS is checksummed, ensuring data integrity. For servers dedicated to storage, ZFS appears to be a "fire and forget" solution, which is easily challenged by its tremendous amount of tunables and parameters.

As preliminary learning and experiments, I sourced some drives for my own workstation and set up two ZFS pools on them. Then I signed up for some private tracker (PT) sites for I/O load to tune for. The results were quite satisfying: In two years and a half, my single-node PT station has generated 1.20 PiB of uploads.

Over the years, I have gathered some of my most important sources for learning ZFS:

- Chris's Wiki: <https://utcc.utoronto.ca/~cks/space/blog/>
- OpenZFS Documentation: <https://openzfs.github.io/openzfs-docs/>
- My own blog: [Understanding ZFS block sizes]({{ "/p/62" | relative_url }})
    - Plus all references in the article

{% include figure
  image_path="https://image.ibugone.com/grafana/qb/2024-06-05.png"
  popup=true
  alt="A Grafana dashboard for qBittorrent"
  caption="A byproduct of my ZFS learning: A Grafana dashboard for qBittorrent (lol...)" %}

After these years of learning ZFS, I realized that there's a substantial room for improvement in our mirror servers, by embracing ZFS and tuning it properly.

## Mirrors

Before we move on to rebuilding the ZFS pool, we need to understand our I/O workload. In essence, a mirror site:

- Provides file downloads
- Also (begrudgingly) serves as speed tests
- Mostly reads, and almost all reads are whole-file sequential reads
- Can withstand minimal data loss as mirror contents can be easily re-synced

{% include figure
  image_path="https://image.ibugone.com/server/mirrors-file-size-distribution-2024-08.png"
  popup=true
  alt="File size distribution of USTC Mirrors in August 2024"
  caption="File size distribution of USTC Mirrors in August 2024" %}

With those in mind, we analyzed our mirror content. As can be seen from the graph above, half of the 40M files are less than 10 KiB in size, and 90% of the files are less than 1 MiB. Still, the files are averaged at 1.6 MiB.

## Rebuilding the Rsync server {#mirrors2}

In June, we set out to rebuild the Rsync server as it had a lower service traffic and importance, yet a disproportionately higher disk usage. We laid out the following plan:

- First, the RAID overhead of RAID-Z3 was too high (reiterating: half of the files are less than 10 KiB, and the disks have 4 KiB sectors), so we decided to switch to RAID-Z2 as well as split the RAID group into two. Two RAIDZ vdevs also implies double the IOPS, as each "block" (in ZFS parlance) is stored on only one vdev.
- We then carefully select dataset properties to optimize for our workload:
  - `recordsize=1M` to maximize sequential throughput and minimize fragmentation
  - `compression=zstd` to (try to) save some disk space
    - Since OpenZFS 2.2, a mechanism called "early-abort" has been extended to Zstd compression (level 3+), which saves CPU cycles by testing data compressibility with LZ4 then Zstd 1, before actually trying to compress with Zstd.

      We know that most of our mirror content is already compressed (like software packages and ISOs), so early-abort is urging us to use Zstd.
  - `xattr=off` as we don't need extended attributes for mirror content.
  - `atime=off` as we don't need access time. Also cuts off a lot of writes.
  - `setuid=off`, `exec=off`, `devices=off` to disable what we don't need.
  - `secondarycache=metadata` to cache metadata only, as this Rsync server has a much more uniform access pattern than the HTTP server. We would like to save our SSDs from unnecessary writes.
- Some slightly dangerous properties:
  - `sync=disabled` to disable synchronous writes. This allows ZFS to buffer writes up to `zfs_txg_timeout` seconds and make better allocation decisions.
  - `redundant_metadata=some` to trade some metadata redundancy for better write performance.

  We believe these changes are in alignment with our evaluation of data safety and loss tolerance.

- For ZFS module parameters, the sheer number of 290+ tunables is overwhelming. Thanks to @happyaron, the current ZFS maintainer in Debian and administrator of BFSU Mirror, we selected a handful of them:

  ```shell
  # Set ARC size to 160-200 GiB, keep 16 GiB free for OS
  options zfs zfs_arc_max=214748364800
  options zfs zfs_arc_min=171798691840
  options zfs zfs_arc_sys_free=17179869184

  # Favor metadata to data by 20x (OpenZFS 2.2+)
  options zfs zfs_arc_meta_balance=2000

  # Allow up to 80% of ARC to be used for dnodes
  options zfs zfs_arc_dnode_limit_percent=80

  # See man page section "ZFS I/O Scheduler"
  options zfs zfs_vdev_async_read_max_active=8
  options zfs zfs_vdev_async_read_min_active=2
  options zfs zfs_vdev_scrub_max_active=5
  options zfs zfs_vdev_max_active=20000

  # Never throttle the ARC
  options zfs zfs_arc_lotsfree_percent=0

  # Tune L2ARC
  options zfs l2arc_headroom=8
  options zfs l2arc_write_max=67108864
  options zfs l2arc_noprefetch=0
  ```

  And also `zfs_dmu_offset_next_sync`, which is enabled by default since OpenZFS 2.1.5, so it's omitted from our list.

After relocating Rsync service to our primary server (HTTP server), we broke up the existing ZFS pool and rebuilt it anew, before syncing previous repositories back from external sources. To our surprise, the restoration took only 3 days, much faster than we had anticipated. Other numbers also looked promising:

- Compression ratio: 39.5T / 37.1T (1.07x)

  We'd like to point out that ZFS only provides two digits after the decimal point for compression ratio, so if you want a higher precision, you need take the raw numbers and calculate it yourself:

  ```shell
  zfs list -po name,logicalused,used
  ```

  Our actual number was 1 + 6.57%, at 2.67 TB (2.43 TiB) saved, which means equivalently 9 copies of WeChat data [as advertised by Lenovo Legion]({{ image_base }}/teaser/lenovo-legion-wechat-data.jpg).

- And most importantly, a much saner I/O load:

  {% include figure
  image_path="https://image.ibugone.com/grafana/mirrors2-io-utilization-and-free-space-june-july-2024.png"
  popup=true
  alt="I/O load of server mirrors2 before and after the rebuild"
  caption="I/O load of server \"mirrors2\" before and after the rebuild" %}

We can see that, after a few days of warm-up, the I/O load has maintained at around 20%, whereas it was constantly at 90% before the rebuild.

## Rebuilding the HTTP server {#mirrors4}

Our HTTP server was set up in late 2020 and under a different background.
When we were first deciding the technology stack, we were not confident in ZFS and were discouraged by the abysmal performance of our Rsync server.
So we opted for an entirely different stack for this server: hardware RAID, LVM (because the RAID controller didn't allow RAID groups across two controllers), and XFS.
For memory caching, we relied on kernel's page cache, and for SSD caching, we tried LVMcache, which was quite new at the moment and rather immature.

These unpracticed technologies have, without a doubt, ended up a pain.

- XFS cannot be shrunk, so we had to reserve free PEs at LVM VG level. We also cannot fill the FS, so there are two levels of free space reservation. Double the waste.
- We initially allocated 1.5 TB of SSD cache, but given LVMcache's recommendation of no more than 1 million chunks, we opted for just 1 TiB (1 MiB chunk size &times; 1 Mi chunks).
- There were no options for cache eviction policy, so later we dug into the kernel source code and found that it was a 64-level LRU.
- The first thing to die was GRUB2. Due to GRUB's parsing of LVM metadata, it was unable to boot from a VG where a cached volume was present. We had to [patch](https://github.com/taoky/grub/commit/85b260baec91aa4f7db85d7592f6be92d549a0ae) GRUB for it to handle this case.
- With an incorrect understanding of chunk size and number of chunks, our SSD ran severely over its write endurance in under 2 years, and we had to replace it with a new one.

Even after understanding the algorithm and still going for 128 KiB chunk size and over 8 Mi chunks, LVMcache still didn't offer a competitive hit rate:

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors4-dmcache-may-june-2024.png"
  popup=true
  alt="LVMcache hit rate over May to June 2024"
  caption="LVMcache hit rate over May to June 2024" %}

We had already been fed up with those troubles through the years, and the success with our Rsync server rebuild gave us great confidence with ZFS.
So in less than a month, we laid out a similar plan for our HTTP server, but trying something new:

- We updated the kernel to `6.8.8-3-pve`, which bundles the latest `zfs.ko` for us. This means we don't have to waste time on DKMS.
- Since the number of disks is the same (12 disks), we also went for two RAID-Z2 vdevs with 6 disks each.
  - As this server provides HTTP service to end users, the access pattern will have a greater hot/cold distinction than the Rsync server. So we keep `secondarycache=all` for this server (leave the default value unchanged).
  - This newer server has a better CPU, so we increased compression level to `zstd-8` in hope for a better compression ratio.
- Since we already have the Rsync server running ZFS with desired parameters, we have `zfs send -Lcp` available when syncing the data back. This allows us to restore 50+ TiB of data in just 36 hours.
- Due to having a slightly different set of repositories, the compression ratio is slightly lower at 1 + 3.93% (2.42 TiB / 2.20 TiB saved).

We put the I/O loads of both servers together for comparison:

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors2-4-io-utilization-june-july-2024.png"
  popup=true
  alt="I/O load of two servers from USTC Mirrors before and after rebuild"
  caption="I/O load of two servers from USTC Mirrors before and after rebuild" %}

This graph starts with the initial state. The first server was rebuilt at 1/3, and the second server was rebuilt at 2/3.

The hit rate of ZFS ARC is also quite satisfying:

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors2-4-zfs-arc-hit-rate.png"
  popup=true
  alt="ZFS ARC hit rate of two servers"
  caption="ZFS ARC hit rate of two servers" %}

The stablized I/O load is even lower after both servers were rebuilt.

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors2-4-disk-io-after-rebuild.png"
  popup=true
  alt="Sustained disk I/O of two servers after rebuild"
  caption="Sustained disk I/O of two servers after rebuild" %}

## Misc

### ZFS compression

We are slightly surprised to see that so many repositories are well-compressible:

| NAME                       | LUSED |  USED | RATIO |
| :------------------------- | ----: | ----: | ----: |
| pool0/repo/crates.io-index | 2.19G | 1.65G | 3.01x |
| pool0/repo/elpa            | 3.35G | 2.32G | 1.67x |
| pool0/repo/rfc             | 4.37G | 3.01G | 1.56x |
| pool0/repo/debian-cdimage  | 1.58T | 1.04T | 1.54x |
| pool0/repo/tldp            | 4.89G | 3.78G | 1.48x |
| pool0/repo/loongnix        |  438G |  332G | 1.34x |
| pool0/repo/rosdistro       | 32.2M | 26.6M | 1.31x |

A few numbers (notably the first one) don't make sense, which we attribute to [<i class="fab fa-github"></i> openzfs/zfs#7639](https://github.com/openzfs/zfs/issues/7639).

If we sort the table by difference, it would be:

| NAME                      |  LUSED |   USED |   DIFF |
| :------------------------ | -----: | -----: | -----: |
| pool0/repo                |  58.3T |  56.1T |   2.2T |
| pool0/repo/debian-cdimage |   1.6T |   1.0T | 549.6G |
| pool0/repo/opensuse       |   2.5T |   2.3T | 279.7G |
| pool0/repo/turnkeylinux   |   1.2T |   1.0T | 155.2G |
| pool0/repo/loongnix       | 438.2G | 331.9G | 106.3G |
| pool0/repo/alpine         |   3.0T |   2.9T | 103.9G |
| pool0/repo/openwrt        |   1.8T |   1.7T |  70.0G |

`debian-cdimage` alone contributes to a quarter of the saved space.

### Grafana for ZFS I/O

We also fixed a Grafana panel for ZFS I/O so it's displaying the correct numbers.
Because ZFS I/O statistics are exported through `/proc/spl/kstat/zfs/$POOL/objset-$OBJSETID_HEX` and is cumulative per "object set" (i.e. dataset), we need to calculate the derivative of the numbers and *then* sum by pool.
This means the use of subqueries is inevitable.

```sql
SELECT
  non_negative_derivative(sum("reads"), 1s) AS "read",
  non_negative_derivative(sum("writes"), 1s) AS "write"
FROM (
  SELECT
    first("reads") AS "reads",
    first("writes") AS "writes"
  FROM "zfs_pool"
  WHERE ("host" = 'taokystrong' AND "pool" = 'pool0') AND $timeFilter
  GROUP BY time($interval), "host"::tag, "pool"::tag, "dataset"::tag fill(null)
)
WHERE $timeFilter
GROUP BY time($interval), "pool"::tag fill(linear)
```

This query is a bit slow (due to the subquery) and unfortunately there's not much we can do about it.

To display I/O bandwidth, simply replace `reads` and `writes` with `nread` and `nwritten` in the inner query.

{% include figure
  image_path="https://image.ibugone.com/grafana/mirrors2-4-zfs-io-count.png"
  popup=true
  alt="ZFS I/O count and bandwidth"
  caption="ZFS I/O count and bandwidth" %}

We are astonished to see an HDD array can sustain 15k IOPS and peaking at 50k IOPS.
This becomes all explained when we discovered that these numbers took ARC hits into account, and a minimal proportion were actually hitting the disks.

### AppArmor

It didn't take long before we noticed all our sync tasks were failing.
We found `rsync` failing with `EPERM` for `socketpair(2)` calls, which never manifested before.
Interestingly, these were denied by AppArmor.
We traced down the cause to be Ubuntu's addition to the kernel, `security/apparmor/af_unix.c`.
As Proxmox VE forks its kernel from Ubuntu, this change also made its way into our server.

We also found PVE packaging their own copy of AppArmor `features`, so we decided to adopt the same approach:

```shell
dpkg-divert --package lxc-pve --rename --divert /usr/share/apparmor-features/features.stock --add /usr/share/apparmor-features/features
wget -O /usr/share/apparmor-features/features https://github.com/proxmox/lxc/raw/master/debian/features
```

### File deduplication

For a small set of repositories, possibly due to limitations of syncing methods, we noticed a lot of identically-looking directories.

{% include figure
  image_path="https://image.ibugone.com/server/ls-zerotier-redhat-el.png"
  popup=true
  alt="Some folders from ZeroTier repository"
  caption="Some folders from ZeroTier repository" %}

ZFS deduplication immediately came to our mind, so we made a preliminary test on ZT:

```shell
zfs create -o dedup=on pool0/repo/zerotier
# dump content into it
```

```console
# zdb -DDD pool0
dedup = 4.93, compress = 1.23, copies = 1.00, dedup * compress / copies = 6.04
```

The results look promising, but we are still hesitant to enable deduplication due to the potential performance impact even on these selected datasets.

Guess what we ended up with?

```shell
# post-sync.sh
# Do file-level deduplication for select repos
case "$NAME" in
  docker-ce|influxdata|nginx|openresty|proxmox|salt|tailscale|zerotier)
    jdupes -L -Q -r -q "$DIR" ;;
esac
```

As attractive as it looks, this userspace file deduplication tool is as good as ZFS can do, but without the performance loss.

| Name        | Orig   | Dedup  | Diff   | Ratio |
|-------------|--------|--------|--------|-------|
| proxmox     | 395.4G | 162.6G | 232.9G | 2.43x |
| docker-ce   | 539.6G | 318.2G | 221.4G | 1.70x |
| influxdata  | 248.4G | 54.8G  | 193.6G | 4.54x |
| salt        | 139.0G | 87.2G  | 51.9G  | 1.59x |
| nginx       | 94.9G  | 59.7G  | 35.2G  | 1.59x |
| zerotier    | 29.8G  | 6.1G   | 23.7G  | 4.88x |
| mysql-repo  | 647.8G | 632.5G | 15.2G  | 1.02x |
| openresty   | 65.1G  | 53.4G  | 11.7G  | 1.22x |
| tailscale   | 17.9G  | 9.0G   | 9.0G   | 2.00x |

We decided to exclude `mysql-repo` as the deduplication ratio is too low to justify the I/O load after each sync.

## Conclusion

ZFS solved a number of problems we had with our mirror servers, and with the current setup, we are delighted to announce that ZFS is *the* best solution for mirrors.

With ZFS:

- We no longer need to worry about partitioning, as ZFS can grow and shrink as needed.
- Our HDD array is now running faster than SSDs. Amazing!
    - Be the first one to no longer **envy** TUNA's SSD server!
- Extra capacity at no cost, thanks to ZFS compression.
    - Even more so with deduplication.

### Considerations

While our ZFS looks very promising, we're aware that ZFS is not known for its long-term performance stability due to fragmentation.
We'll continue to monitor our servers and see if this performance is sustainable.
