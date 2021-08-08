---
title: "Linux IP routing and routing rules"
tags: linux networking
redirect_from: /p/32

published: false
---

In larger organizations and corporations, it's common to have multiple ISPs connected to one datacenter. It's important to provide faster connectivity to users by optimizing for different networks, which is called **routing**. This article explains how a Linux system route network traffic to different networks. I'll start with the basic.

## The main routing table

**Routing** is the process of determining where certain traffic should be directed to. On systems with only one network interface, it's as simple as sending all traffic to that sole interface. Still, it's not usually as simple as a single routing rule. There are often two. Say for example, a VM running on my computer is connected to an internal network with an address of 192.168.2.100/24, then it will have the following two routing rules, visible using the command `ip route` (or `ip route show`):

```text
default via 192.168.2.1 dev eth0
192.168.2.0/24 dev eth0
```

The second line indicates that the network 192.168.2.0/24 is on the same link, so there's no need to send traffic to a gateway to be forwarded. The first line, starting with `default`, means that if a packet doesn't match *any other* rule in the routing table, it will be sent to the gateway with an IP address of 192.168.2.1.

Now when I connect the VM to an extra network with IP 192.168.3.100/24, Linux will automatically add an extra rule to the routing table.

```text
192.168.3.0/24 dev eth1
```

Instead of wrongly trying to reach 192.168.3.0/24 via the gateway 192.168.2.1, Linux will now try to reach it directly from interface `eth1`.
