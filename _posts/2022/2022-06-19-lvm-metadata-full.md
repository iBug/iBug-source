---
title: "LVM metadata exceeds maximum metadata size, now what next?"
tags: linux server
redirect_from: /p/52
---

An LVM volume group (VG) on our Proxmox VE cluster has failed to create new logical volumes, reporting that its metadata was full. At first this appears to be easy, “fine I’ll just add more space for metadata”, but it quickly revealed to be an versity to struggle through.

```console
root@iBug-Server:~# lvcreate -L 4M -n test-1721 test
  VG test 1723 metadata on /dev/sdc1 (521759 bytes) exceeds maximum metadata size (521472 bytes)
  Failed to write VG test.
root@iBug-Server:~# # wut?
```

## Problems

It isn’t hard to imagine that, just like regular disks need a partition table, LVM also needs its “partition table”, called *LVM metadata*, to store its information about PVs, VGs and LVs. It grows with the complexity of a VG, like number of PVs and configuration of LVs.

The metadata size and capacity of a PV and a VG can be inspected with `pvdisplay` and `vgdisplay`, respectively.

```console
root@iBug-Server:~# pvdisplay -C -o name,mda_size,mda_free
  PV         PMdaSize  PMdaFree
  /dev/sdc1   1020.00k        0
root@iBug-Server:~# vgdisplay -C -o name,mda_size,mda_free
  VG   VMdaSize  VMdaFree
  test  1020.00k        0
```

The metadata area (whence `mda`) is where LVM stores volume information. The trouble comes from the fact that LVM MDA has multiple oddities going against intuition, which adds to the complexity of findin a solution.

### 1. “Metadata” is an ambiguous term

If you just go ahead and search for “LVM metadata size”, you’ll be surprised to see how irrelevant the search results are. In fact, they’re about “thin pool metadata”, which is a discrete LV usually named `poolname_tmeta`. 

In fact, the correct answer is in the man page, which should show up as the first Google result, [`pvcreate(8)`](https://man7.org/linux/man-pages/man8/pvcreate.8.html). This is where I discovered the use of `pvs` and `vgs` to get the sizes.

### 2. The default MDA size is fixed

Contrary to common expectations, the default value for MDA size is *fixed* and does not scale with PV size or VG size. This is explained in the man page, right above `pvs -o mda_size`. 

This is not the case, however, for LVM Thin Pools. It’s not known what the design considerations are behind this.

### 3. The size of the MDA cannot be changed after creation

As many would probably have, I also thought that “fine, I’ll just expand the size for the MDA”, and started digging through Google and relevant man pages. Another quarter-hour was spent trying to find how to do this, only to find that it can only be set at the creation of the PV. This was confirmed by [this Proxmox forum post](https://forum.proxmox.com/threads/cannot-create-more-snapshot-without-deleting-some-olds-one.110112/).

### 4. Reducing “metadata copies” does not free up space

There’s also a `pvmetadatacopies` option listed in both `vgchange(8)` and `pvchange(8)`, which appears tempting to give a try. Unfortunately, opposite to intuition again, this does not free up half of the MDA space. Setting it to 1 down from the default 2 produces no visible changes.

## Finding the solution

At this point I had figured out a silhouette for the problem I was facing: A VG on a single PV, fixed MDA size, no room to free up any metadata.

Fortunately, the shared SAN target supports “overcommitting”, meaning I can have an extra LUN with little effort. Given that the utilized storage is slightly over 50%, it’s not possible to move data onto the new LUN. Even if there were enough free space, moving data would take an infeasible amount of time. Ideally this new LUN shouldn’t be too large, to minimize possible aftermath should the underlying disk group goes full.

So, how can this trouble be overcome, with the help of a new LUN?

------

Digging into this level of details, Google is unable to help, so I had to resort to man pages, if I did not have to check the source codes.

Looking at `pvchange(8)`, the only modifiable property of an existing PV is `metadataignore`. It instructs LVM to ignore the MDA for a PV.

A possible solution has arisen: Create a new PV with large enough MDA, merge it into the VG, and disable metadata storage on the old PV.

## Solution

I created a new LUN in the storage server’s dashboard and loaded it onto all servers in the cluster using `iscsiadm`:

```shell
iscsiadm -m session --rescan
```

The rescan may have some delay so I continued monitoring it for a minute before `/dev/sdd` showed up on all hosts.

Now I turn the new block device into a PV and add it to the problematic VG:

```shell
pvcreate --metadatasize 64m /dev/sdd
vgextend test /dev/sdd
```

Partly to my surprise, a warning popped up:

```shell
VG test 1723 metadata on /dev/sdc1 (521615 bytes) exceeds maximum metadata size (521472 bytes)
WARNING: Failed to write an MDA of VG test.
Volume group "test" successfully extended
```

This one isn’t hard to understand: The VG metadata must record the identifiers of all participating PVs, so adding a PV means more metadata to be stored.

So before pulling this off, I had to remove a LV temporarily. I had a few laying around for testing purposes, so finding one to get rid of was not hard. After that I could repeat the `vgextend` command without a single warning.

Next I exclude the original PV from storing metadata:

```shell
pvchange --metadataignore y /dev/sdc1
```

Now I can add another LV inside this VG without error:

```console
root@iBug-Server:~# lvcreate -L 1M -n test-1721 test
  Rounding up size to full physical extent 4.00 MiB
  Logical volume "test-1721" created.
root@iBug-Server:~# pvs -o name,mda_size,mda_free
  PV         PMdaSize  PMdaFree
  /dev/sdc1   1020.00k        0
  /dev/sdd     <65.00m   <32.00m
```

## Caveats

LVM by default stores an identical copy of the metadata on every PV that belongs to the same VG. Using this “solution”, the complete metadata is only stored on the newly created PV. You certainly want to use reliable storage for this new PV as it’s now a [SPOF](https://en.wikipedia.org/wiki/Single_point_of_failure) of the whole VG.

If in any case you want a copy of the metadata for inspection or to recover a failed VG (hope you don’t need to do that), LVM maintains automatic backups under `/etc/lvm/backup`. They’re in their original form, are text-based (so easily readable), and are ready for use with `vgcfgrestore`.

Indeed, the recommended solution is to create a new, larger VG and migrate your data ASAP. After all, data security matters the most.
