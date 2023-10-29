---
title: "Understanding ZFS block sizes"
tags: linux zfs
redirect_from: /p/-2
---

ZFS is about the most complex filesystem for single-node storage servers. Coming with its sophistication is its equally confusing "block size", which is normally self-evident on common filesystems like ext4 (or more primitively, FAT). The enigma continues as ZFS bundles more optimizations, either for performance or in the name of "intuition" (which I would hardly agree). So recently I read a lot of materials on this and try to make sense of it.

We'll begin with a slide from a ZFS talk from Lustre[^dilger] (page 5):

![ZFS I/O Stack](/image/zfs/zfs-io-stack.png)

## Logical blocks

The first thing to understand is that there are at least two levels of "block" concepts in ZFS. There's "logical blocks" on an upper layer (DMU), and "physical blocks" on a lower layer (vdev). The latter is easier to understand and it's almost synonymous to "disk sectors". It's precisely the `ashift` parameter in `zpool create` command and usually matches the physical sector size of your disks (4 KiB for modern disks). Once set, `ashift` is immutable and can only be changed when recreating the entire vdev array (fortunately not the entire pool[^zfs101]). The "logical block", however, is slightly more complicated, and beyond the expressibility of a few words. In short, it's the smallest *meaningful* unit of data that ZFS can operate on, including reading, writing, checksumming, compression and deduplication.

### "recordsize" and "volblocksize"

You've probably seen `recordsize` being talked about extensively in ZFS tuning guides[^tuning], which is already a great source of confusion. The default `recordsize` is 128 KiB, which controls the *maximum* size of a logical block. The *actual* block size depends on the file you're writing:

- If the file is smaller than or equal to `recordsize`, it's stored as a single logical block of its size, rounded up to the nearest multiple of 512 bytes.
- If the file is larger than `recordsize`, it's split into multiple logical blocks of `recordsize` each, with the last block being zero-padded to `recordsize`.

As with other filesystems, if you change a small portion of a large file, only 128 KiB (or whatever your `recordsize` is) is rewritten, along with new metadata and checksums. For this reason, it's inadvisable to set `recordsize` too small, as it would incur high overhead for associated metadata and checksums. It is more important, however, to align your `recordsize` with your workload, like using 16 KiB for (most) databases and 1 MiB for media files. Note that ZFS always validates checksums, so every read operation is done on an entire block, even if only a few bytes are requested.

For ZVOLs, as you'd imagine, the rule is much simpler: Every block of `volblocksize` is a logical block, and it's aligned. Since ZFS 2.1, the default `volblocksize` is 16 KiB, providing a good balance between performance and compatibility.

### Compression

Compression is applied on a per-block basis, and compressed data is not shared between blocks. This is best shown with an example:

```console
$ zfs get compression tank/test
NAME       PROPERTY     VALUE  SOURCE
tank/test  compression  zstd   inherited from tank
$ head -c 131072 /dev/urandom > 128k
$ cat 128k 128k 128k 128k 128k 128k 128k 128k > 1m
$ du -sh 128k 1m
129K    128k
1.1M    1m
```

```console
$ head -c 16384 /dev/urandom > 16k
$ cat 16k 16k 16k 16k 16k 16k 16k 16k > 128k1
$ cat 128k1 128k1 128k1 128k1 128k1 128k1 128k1 128k1 > 1m1
$ du -sh 16k 128k1 1m1
17K     16k
21K     128k1
169K    1m1
```

As you can see from `du`'s output above, despite containing 8 identical copies of the same 128 KiB random data, the 1 MiB file gains precisely nothing from compression, as each 128 KiB block is compressed individually. The other test of combining 8 copies of 16 KiB random data into one 128 KiB file shows positive results, as the 128 KiB file is only 21 KiB in size. Similarly, the 1 MiB file that contains 64 exact copies of the same 16 KiB chunk is exactly 8 times the size of that 128 KiB file, because the chunk data is not shared across 128 KiB boundaries.

This brings up an interesting point: **It's beneficial to turn on compression even for filesystems with uncompressible data**[^cks-1]. One direct impact is on the last block of a large file, where its zero-filled bytes up to `recordsize` compress very well. Using LZ4 or ZSTD, compression should have negligible impact on any reasonably modern CPU.

There are two more noteworthy points about compression, both from [`man zfsprops.7`][zfsprops.7]:

1. > When any setting except **off** is selected, compression will explicitly check for blocks consisting of only zeroes (the NUL byte). When a zero-filled block is detected, it is stored as a hole and not compressed using the indicated compression algorithm.

    Instead of compressing entire blocks of zeroes like the last block of a large file, ZFS will not store anything about these zero blocks. Technically, this is done by omitting the corresponding ranges from the file's indirect blocks[^cks-1].

2. > Any block being compressed must be no larger than 7/8 of its original size after compression, otherwise the compression will not be considered worthwhile and the block saved uncompressed. \[...\] for example, 8 KiB blocks on disks with 4 KiB disk sectors must compress to 1/2 or less of their original size.

## RAIDZ

Up until now we've only talked about logical blocks, which are all on the higher layers of the ZFS hierarchy. RAIDZ is where physical blocks (disk sectors) really come into play and adds another field of confusion.

Unlike traditional RAID 5/6/7 that combines disks into an array and presents a single virtual disk to the filesystem, RAIDZ handles each *logical block* separately.

I'll cite this illustration from Delphix[^delphix] to explain:

![RAID-Z block layout](/image/zfs/raidz-block-layout.png)

This example shows a 5-wide RAID-Z1 setup.

- A single-sector block takes another sector for parity, like the dark red block on row 3.
- Multi-sector blocks are striped across disks, with parity sectors inserted every 4 sectors, matching the data-to-parity ratio of the vdev array.

    You may have noticed that parity sectors for the same block are always stored on the same disk that resembles RAID-4 instead of RAID-5. Keep in mind that ZFS reads, writes and verifies entire blocks, so interleaving parity sectors across disks will not provide any benefit, while keeping "stripes" on the same disk simplifies the logic for validation and reconstruction.

- In order to avoid unusable fragments, ZFS requires each allocated block to be padded to a multiple of (p+1) sectors, where *p* is the number of parity disks. For example, RAID-Z1 requires each block to be padded to a multiple of 2 sectors, and RAID-Z2 requires each block to be padded to a multiple of 3 sectors. This can be seen on rows 7 to 9, where the X sectors are reserved for parity padding.

This design allows RAID to play well with ZFS's log-structured design and avoids the need for read-modify-write cycles. Consequently, the RAID overhead is now dependent on your data and is no longer an intrinsic property of the RAID level and array width.

The same Delphix article[^delphix] shares a nice spreadsheet that calculates RAID overhead for you:

[![Size of parity overhead for RAID-Z1](/image/zfs/raidz1-parity-overhead.png)](https://docs.google.com/a/delphix.com/spreadsheets/d/1tf4qx1aMJp8Lo_R6gpT689wTjHv6CGVElrPqTA0w_ZY/)

### Accounting {#raidz-accounting}

Accounting the storage space for a RAIDZ array is as problematic as it seems: There's no way to calculate the available space in advance without knowledge on the block size pattern.

ZFS works around this by showing an estimate, assuming all data were stored as 128 KiB blocks[^zfs-4599].


  [delphix]: https://www.delphix.com/blog/zfs-raidz-stripe-width-or-how-i-learned-stop-worrying-and-love-raidz
  [dilger]: https://wiki.lustre.org/images/4/49/Beijing-2010.2-ZFS_overview_3.1_Dilger.pdf
  [zfs-4599]: https://github.com/openzfs/zfs/issues/4599
  [zfsprops.7]: https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html
  [tuning]: https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html

  [^cks-1]: Chris Siebenmann (2017) [ZFS's recordsize, holes in files, and partial blocks](https://utcc.utoronto.ca/~cks/space/blog/solaris/ZFSFilePartialAndHoleStorage)
  [^delphix]: Matthew Ahrens (2014) [How I Learned to Stop Worrying and Love RAIDZ][delphix]
  [^dilger]: Andreas Dilger (2010) [ZFS Features & Concepts TOI][dilger]
  [^tuning]: [Workload Tuning][tuning]
  [^zfs101]: Jim Salter (2020) [ZFS 101 &ndash; Understanding ZFS storage and performance](https://arstechnica.com/information-technology/2020/05/zfs-101-understanding-zfs-storage-and-performance/)
  [^zfs-4599]: openzfs/zfs#4599: [disk usage wrong when using larger recordsize, raidz and ashift=12][zfs-4599]
