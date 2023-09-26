---
title: "Running a dual-protocol OpenVPN/WireGuard VPN server on one port"
tags: linux networking
redirect_from: /p/60
header:
  teaser: /image/teaser/wireguard-openvpn.jpg
  overlay_filter: 0.1
  overlay_image: /image/header/sunshine-1.jpg
---

Public Wi-Fi and some campus network typically block traffic from unauthenticated clients, but more often allow traffic targeting UDP port 53 to pass through, which is normally used for DNS queries. This feature can be exploited to bypass authentication by connecting to a VPN server that's also running on UDP 53.

In previous times, OpenVPN was the general preference for personal VPN services. Since the emergence of WireGuard, however, popularity has shifted significantly for its simplicity and performance. A challenge presents itself as there's only one UDP port numbered 53, making it seemingly impossible to run both OpenVPN and WireGuard on the same port.

There solution hinges itself on a little bit of insights.

## Inspiration

In a similar situation, many local proxy software like Shadowsocks and V2ray support a feature called "mixed mode", which accepts both HTTP and SOCKS5 connections on the same TCP port. This also seems impossible at first glance, but with a bit of knowledge in both protocols, it's actually easy to pull it off.

- An HTTP proxy request, just like other HTTP requests, begins with an HTTP verb. In proxy requests, it's either `GET` or `CONNECT`,
- A SOCKS proxy request begins with a 1-byte header containing its version, which is `0x04` for SOCKS4 or `0x05` for SOCKS5.

Now there's a clear line between the two protocols, and we can identify them by looking at the first byte of the request. This is how most proxy implementations work, like [3proxy][3proxy] and [glider][glider].

So the question is, is there a similar trait between OpenVPN and WireGuard? The answer is, as you would expect, yes.

  [3proxy]: https://github.com/3proxy/3proxy/commit/fb56b7d307a7bce1f2109c73864bad7c71716f3b#diff-e268b23274bc9df1b2c0957dfa85d684519282ed611f6135e795205e53fb6e3b
  [glider]: https://github.com/nadoo/glider/blob/4f12a4f3082940d8a4c56ba4f06f02a72d90d5d6/proxy/mixed/mixed.go#L84

## Protocols

WireGuard runs over UDP and defines 4 packet types: 3 for handshake and 1 for data. All 4 packet types share the same 4-byte [header][wg-header]:

  [wg-header]: https://github.com/WireGuard/wireguard-linux/blob/fa41884c1c6deb6774135390e5813a97184903e0/drivers/net/wireguard/messages.h#L65

```rust
struct message_header {
    u8 type;
    u8 reserved_zero[3];
}
```

Similarly, all OpenVPN packet types share the same 1-byte [header][ovpn-header]:

  [ovpn-header]: https://build.openvpn.net/doxygen/network_protocol.html#network_protocol_external_types

```c
struct header_byte {
    uint8_t opcpde : 5;
    uint8_t key_id : 3;
}
```

It's worth noting that 0 is not a defined opcode, so the smallest valid value for this byte is 8, as `key_id` can be anything from 0 to 7.

## Implementation

Now that we have the packet format for both protocols understood, we can implement a classifier that filters traffic in one protocol from the other.

Considering that the WireGuard packet format is much simpler than that of OpenVPN, I choose to identify WireGuard. With kernel firewall `iptables`, options are abundant, though I find `u32` the easiest:

```sh
*nat
:iBugVPN - [0:0]
-A PREROUTING -m addrtype --dst-type LOCAL -p udp --dport 53 -j iBugVPN
-A iBugVPN -m u32 --u32 "25 & 0xFF = 1:4 && 28 & 0xFFFFFF = 0" -j REDIRECT --to-port 51820
-A iBugVPN -j REDIRECT --to-port 1194
COMMIT
```

With both OpenVPN and WireGuard running on their standard ports, this will redirect each protocol to its respective service port. While these rules only operate on the initial packet, Linux conntrack will handle the rest of the connection.

The `u32` match is explained:

- Basic syntax: `<offset> [operators...] = <range>`, where `<offset>` is relative to the IP header. For UDP over IPv4, the application payload starts from 28 (20 bytes of IPv4 and 8 bytes of UDP)
- `25 & 0xFF = 1:4`: The 28th byte is in range `1:4`.
- `28 & 0xFFFFFF = 0`: The 29th to 31th bytes are all zero.

For IPv6, you just need to increase the offset by 20 (IPv6 header is 40 bytes), so the rule becomes `45 & 0xFF = 1:4 && 48 & 0xFFFFFF = 0`.

This VPN server is running like a hearse so proofs are left out for brevity.
