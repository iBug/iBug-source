---
title: USTC Virtualization Laboratory
excerpt: "An in-school cloud computing provider that I set up from scratch. Provides virtual machines and block storage for students to do course experiments."
date: 1970-01-03
header:
  teaser: /image/teaser/project/cloud-computing.jpg
---

USTC Virtualization Laboratory (Vlab) is a unified course experiment platform focusing on virtual machines.

Students and faculty log in to their accounts and manage or connect to their virtual machines,
and can do course experiments anywhere without having to spin up messy environments on their own.
We provide a variety of methods to access the VMs,
including VNC (both web-based and through general VNC clients),
SSH (again, either with a web-based terminal or standard SSH clients),
and an in-browser VS Code powered by [code-server](https://github.com/coder/code-server).

Vlab is powered by many open-source software, both ready-made and custom-built.

- The VM manager itself is a Django app, and the front end utilizes Twitter Bootstrap.
- The VM backend is a cluster of Proxmox VE servers, with storage being LVM over SAN (iSCSI).
- The VNC gateway is a custom-built C++ server that "reverse-proxies" VNC connections to user VMs based on authentication.
- The SSH gateway is another of our own server that does the same for SSH connections.
  It's written in Go based on our modified `golang.org/x/crypto/ssh` library.
- The web-based VNC is powered by noVNC and supported by our VNC gateway.
- The web-based SSH terminal is a Go-written SSH client, compiled into WebAssembly, combined with xterm.js.
- The browser VS Code is code-server.

We also have an extensive [documentation](https://vlab.ustc.edu.cn/docs/) for users,
as well as several [guides](https://soc.ustc.edu.cn/) for course instructors to set up their own course experiments.

Since Spring 2020, Vlab has been running steadily, serving over 2000 concurrent users and over 5000 cumulative users. Our team received an *Honorary Certificate for Outstanding Service* from the CS department in May 2021.

Over the years, we have developed a wide range of software and tools to tackle a variety of challenges of running a large-scale cloud computing platform. Parts of Vlab is open-source on [GitHub](https://github.com/USTC-vlab). Technical details are available on [our maintenance documentation](https://vlab.ibugone.com) (Simplified Chinese).

![Vivado in Browser](/image/vlab/vlab-in-browser.jpg)
