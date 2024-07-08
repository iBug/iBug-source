---
title: "Driving pppd with systemd"
tags: linux networking
redirect_from: /p/69
---

I moved my soft router (Intel N5105, Debian) from school to home, and at home it's behind an ONU on bridge mode, so it'll have to do PPPoE itself.

Getting started with PPPoE on Debian is exactly the same as on Ubuntu: Install `pppoeconf` and run `pppoeconf`, then fill in the DSL username and password. Then I can see `ppp0` interface up and working.

However, as I use `systemd-networkd` on my router while `pppd` appears to bundle ifupdown, I'll have to fix everything needed for `pppd` to work with systemd-networkd.

## Systemd service

The first thing is to get it to start at boot. Looking through Google, a [Gist](https://gist.github.com/rany2/330c8fe202b318cacdcb54830c20f98c) provides the exact systemd service file I need. After copying it to `/etc/systemd/system/ppp@.service`, I tried to start it with `systemctl start pppd@dsl-provider`. It seems like there's a misconfiguration:

```text
/usr/sbin/pppd: Can't open options file /etc/ppp/peers/dsl/provider: No such file or directory
```

The instance name is surely `dsl-provider` and not `dsl/provider`, so I look more closely at the service file.

```ini
[...]
Description=PPP connection for %I
[...]
ExecStart=/usr/sbin/pppd up_sdnotify nolog call %I
```

The systemd man page [`systemd.unit(5)`](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) says:

> | Specifier | Meaning | Details |
> | --- | --- | --- |
> | "%i" | Instance name | For instantiated units this is the string between the first "@" character and the type suffix. Empty for non-instantiated units. |
> | "%I" | Unescaped instance name | Same as "%i", but with escaping undone. |

Fair enough, let's change `%I` to `%i` and try starting `pppd@dsl-provider` again.

## systemd-networkd

Now that `ppp0` is up, time to configure routes and routing rules with `systemd-networkd`. I created a file `/etc/systemd/network/10-ppp0.network`.

```ini
[Match]
Name=ppp0

[Network]
DHCP=yes
# ...
```

After restarting systemd-networkd, I was disappointed to see the PPP-negotiated IP address removed, only leaving an SLAAC IPv6 address behind. With some searching through `systemd.network(5)`, I found `KeepConfiguration=yes` was what I was looking for.

## Start order

One problem still remains: At the time systemd-networkd starts, `ppp0` is not yet up, and systemd-networkd simply skips its configuration. A solution seems trivial:

```ini
# systemctl edit pppd@dsl-provider
[Unit]
Before=systemd-networkd.service
```

... except it doesn't seem to have any effect.

I wouldn't bother digging into pppd, so I look around for something analogous to ifupdown's `up` script, which is `/etc/ppp/ip-up.d/`. So I could just drop another script to notify systemd-networkd.

```shell
# /etc/ppp/ip-up.d/1systemd-networkd
#!/bin/sh

networkctl reconfigure "$PPP_IFACE"
```

I also noticed that when bringing in ifupdown, the `pppoeconf`-created config looks like this:

```shell
auto dsl-provider
iface dsl-provider inet ppp
    pre-up /bin/ip link set enp3s0 up # line maintained by pppoeconf
    provider dsl-provider
```

So to maintain behavioral compatibility, I configured the systemd service like this:

```ini
# systemctl edit pppd@dsl-provider
[Unit]
BindsTo=sys-subsystem-net-devices-enp3s0.device
After=sys-subsystem-net-devices-enp3s0.device
```

After multiple reboots and manual restarts of `pppd@dsl-provider.service`, I'm convinced that this is a reliable solution.

## Extra: IPv6 PD {#extra}

As the home ISP provides IPv6 Prefix Delegation (but my school didn't), it would be nice to take it and distribute it to the LAN. Online tutorials are abundant, e.g. [this one](https://major.io/p/dhcpv6-prefix-delegation-with-systemd-networkd/){: rel="nofollow noopener" }. With everything set supposedly up, I was again disappointed to see only a single SLAAC IPv6 address on `ppp0` itself, and `journalctl -eu systemd-networkd` shows no sign of receiving a PD allocation.

After poking around with `IPv6AcceptRA=` and `[DHCPv6] PrefixDelegationHint=` settings for a while, I decided to capture some packets for investigation. I started `tcpdump -i ppp0 -w /tmp/ppp0.pcap icmp6 or udp port 546` and restarted `systemd-networkd`. After a few seconds, the pcap file contains exactly 4 packets that I need (some items omitted for brevity):

```markdown
- ICMPv6: Router Solicitation from 00:00:00:00:00:00
- ICMPv6: Router Advertisement from 00:00:5e:00:01:99
  - Flags: 0x40 (only O)
  - ICMPv6 Option: Prefix information (2001:db8::/64)
    - Flags: L + A
- DHCPv6: Information-request XID: 0x8bf4f0 CID: 00020000ab11503f79e54f10745d
  - Option Request
    - Option: Option Request (6)
    - Length: 10
    - Requested Option code: DNS recursive name server (23)
    - Requested Option code: Simple Network Time Protocol Server (31)
    - Requested Option code: Lifetime (32)
    - Requested Option code: NTP Server (56)
    - Requested Option code: INF_MAX_RT (83)
- DHCPv6: Reply XID: 0x8bf4f0 CID: 00020000ab11503f79e54f10745d
```

Clearly the client isn't even requesting a PD allocation with `PrefixDelegationHint=` set. With some more Google-ing, I added `[DHCPv6] WithoutRA=solicit` to `10-ppp0.network` and restarted `systemd-networkd`. There are 6 packets, but the order appears a little bit off:

```markdown
- Solicit XID: 0x2bc2aa CID: 00020000ab11503f79e54f10745d
- Advertise XID: 0x2bc2aa CID: 00020000ab11503f79e54f10745d
- Request XID: 0xf8c1dd CID: 00020000ab11503f79e54f10745d
  - Identity Association for Prefix Delegation
- Reply XID: 0xf8c1dd CID: 00020000ab11503f79e54f10745d
- Router Solicitation from 00:00:00:00:00:00
- Router Advertisement from 00:00:5e:00:01:99
```

This time DHCP request comes *before* the RS/RA pair, which is not what I expected. But at least it's now requesting a PD prefix.

Then I found [this answer](https://unix.stackexchange.com/a/715025/211239) straight to the point, summarized as:

- The "managed" (M) flag indicates the client should acquire an address via DHCPv6, and triggers DHCPv6 Solicit and Request messages.
- The "other" (O) flag indicates the client should do SLAAC while acquiring other configuration information via DHCPv6, and triggers DHCPv6 Information-request messages.
- When both flags are present, the O flag is superseded by the M flag and has no effect.

So systemd-networkd is implementing everything correctly, and I should configure systemd-networkd to always send Solicit messages regardless of the RA flags received. This is done by setting `[IPv6AcceptRA] DHCPv6Client=always`

Now with every detail understood, after a restart of `systemd-networkd`, I finally see the PD prefix allocated:

```text
systemd-networkd[528]: ppp0: DHCP: received delegated prefix 2001:db8:0:a00::/60
systemd-networkd[528]: enp1s0: DHCP-PD address 2001:db8:0:a00:2a0:c9ff:feee:c4b/64 (valid for 2d 23h 59min 59s, preferred for 1d 23h 59min 59s)
systemd-networkd[528]: enp2s0: DHCP-PD address 2001:db8:0:a01:2a0:c9ff:feee:c4c/64 (valid for 2d 23h 59min 59s, preferred for 1d 23h 59min 59s)
```

## Sum up

- Use systemd to start `pppd` as a system service.
  - Order it before `network.target`, but don't bother with `systemd-networkd.service`.
- Add `KeepConfiguration=yes` to systemd-networkd.
- Use a custom script in `ip-up.d` to invoke systemd-networkd to reconfigure after it's up.
- For IPv6 PD, use both:

  ```ini
  [DHCPv6]
  PrefixDelegationHint=::/60

  [IPv6AcceptRA]
  DHCPv6Client=always
  ```
