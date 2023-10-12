---
title: USTC Virtualization Laboratory
excerpt: "An in-school cloud computing provider that I set up from scratch. Provides virtual machines and block storage for students to do course experiments."
date: 1970-01-03
header:
  teaser: /image/teaser/project/cloud-computing.jpg
---

USTC Virtualization Laboratory (Vlab) is a unified course experiment platform focusing on virtual machines.
Students log in to their accounts and manage or connect to their virtual machines,
and can do course experiments anywhere without having to spin up messy environments on their own.

The VM manager itself is a Django app, and the front end utilizes Twitter Bootstrap.
The VM backend is a cluster of Proxmox VE servers, with storage being LVM over SAN (iSCSI).

Since Spring 2020, Vlab has been running steadily, serving up to 1800 concurrent users and over 4000 cumulative users. Our team received an *Honorary Certificate for Outstanding Service* from the CS department in May 2021.

Over the years, we have developed a wide range of software and tools to tackle a variety of challenges of running a large-scale cloud computing platform. Parts of Vlab is open-source on [GitHub](https://github.com/USTC-vlab). Technical details are available on [our maintenance documentation](https://vlab.ibugone.com) (Simplified Chinese).

![Vivado in Browser](/image/vlab/vlab-in-browser.jpg)
