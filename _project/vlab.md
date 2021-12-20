---
title: USTC Virtualization Laboratory
excerpt: "An in-school cloud computing provider that I set up from scratch. Provides virtual machines and block storage for students to do course experiments."
date: 1970-01-03
header:
  teaser: /image/teaser/cloud-computing.jpg
---

USTC Virtualization Laboratory (Vlab) is a unified course experiment platform involving code storage (GitLab CE) and experiment environment (virtual machines).
Students log in to their accounts and manage or connect to their virtual machines,
and can do course experiments anywhere without having to spin up messy environments on their own.

The VM manager itself is a Django app, and the front end utilizes Twitter Bootstrap.
The VM backend currently consists of LXD and QEMU / libvirt / KVM, with storage part involving LVM and ZFS.

The Next Generation&trade; Vlab runs on Proxmox VE and is more sophisticated. It's currently under construction.
