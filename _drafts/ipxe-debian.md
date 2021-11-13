---
title: "Reinstall VPS into Debian with iPXE network booting"
tags: linux
redirect_from: /p/46

published: false
---



![](/image/linux/ipxe/get-vps.png)

iPXE commands:

```shell
set net0/ip 192.0.2.2
set net0/netmask 255.255.255.0
set net0/gateway 192.0.2.1
set dns 8.8.8.8
ifopen net0
chain --autofree http://boot.netboot.xyz
```

  [netboot]: https://netboot.xyz/docs/booting/ipxe
  [ipxe-set]: https://ipxe.org/cmd/set