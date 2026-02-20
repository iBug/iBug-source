---
title: "BanD Width! It's MyBOND!!"
tagline: "Can bonding bring double upload?"
tags: linux networking
redirect_from: /p/78
header:
  overlay_image: /image/header/band-width-mygo.jpg
  overlay_filter: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.1))
---

My workstation in my univerity lab has consistently generated some 600 TiB of annual upload across two PT sites. After an upgrade to the room a few months back, it received the most wanted upgrade for years: A second 1 Gbps line to the campus network. I immediately made the two NICs into one bonded 2 Gbps interface, and it has shined for many times with multiple popular torrents.

Inspired by my friend [@TheRainstorm](https://blog.yfycloud.site/about/) who managed to double his upload by load-balancing WireGuard over two lines from the same ISP (China Mobile), I figured I'd leverage this chance and make a better understanding though some more detailed experiments.

## Setup

### Sender

My workstation:

- Ubuntu 24.04 (Kernel 6.8)
- Two Intel I210 NICs, connected to the same switch of campus network
- iperf 3.16

Controlled variables:

- Bond mode: Round-robin (`balance-rr`, 0) vs Transmit Load Balancing (`balance-tlb`, 5)
  - For `balance-tlb` mode, `xmit_hash_policy` is set to `layer3+4`.
- TCP congestion control (CC) algorithm: CUBIC vs BBR
- Parallelism (the value to `-P` option of iperf3): 1 vs 4
  - Note that due to the way `balance-tlb` works, with only one connection, bonding is not going to be different than using only one NIC.
<!--
- Whether another application is constantly generating background upload activity.
  - This is implemented by letting qBittorrent run in the background with upload rate limited to 1 MB/s, and is labeled `qB` during the experiment.
-->

These variables combine into 8 different scenarios, which is enough dimensions to look at in isolation.

### Receivers

I sourced three destination (receiver) hosts with > 2 Gbps download bandwidth, labeled as following:

- **A**. One of our usually idle lab servers.
- **B**. [USTC Mirrors](https://mirrors.ustc.edu.cn/) server.
- **C**. Friend-sponsored home broadband in Shanghai.

Typical traits of these destinations are:

| Destination | Download BW | Latency | BDP\* | Other notes |
| :--: | :--: | :--: | :--: | :--- |
| A | 10 Gbps | 250 ± 30 us | 500 KB | Mostly idle |
| B | 10 Gbps | 300 ± 200 us | 600 KB | Under constant load |
| C | ~2.2 Gbps | 28 ± 0.2 ms | 56 MB | Mostly idle |

\* Because my workstation can only generate upload at a theoretical maximum speed of 2 Gbps, BDP is calculated at this speed.

## Analyses

iperf3 provides three indicators: Transmission bitrate, number of retransmissions and the congestion window size.

We cannot attach too much importance to the bond mode when testing bonding performance, so let's get straight to it.

### Single stream

| Dest | P | CC | Bitrate (RR) | Bitrate (TLB) | Retr (RR) | Retr (TLB) | Cwnd (RR) | Cwnd (TLB) |
| :--: | :--: | :--: | ---: | ---: | ---: | ---: | ---: | ---: |
| A | 1 | BBR | 1.78 Gbps | 940 Mbps | 20079 | 20 | 331 KB | 233 KB |
| A | 1 | CUBIC | 1.19 Gbps | 936 Mbps | 7258 | 110 | 103 KB | 385 KB |
| B | 1 | BBR | 1.62 Gbps | 944 Mbps | 37018 | 51 | 343 KB | 241 KB |
| B | 1 | CUBIC | 1.19 Gbps | 941 Mbps | 6914 | 72 | 98 KB | 338 KB |
| C | 1 | BBR | 1.11 Gbps | 935 Mbps | 0 | 0 | 8.87 MB | 7.67 MB |
| C | 1 | CUBIC | 1.16 Gbps | 931 Mbps | 0 | 0 | 6.44 MB | 4.20 MB |

We first look at `balance-tlb` mode.
As expected, with one single stream, it runs on only one slave interface (confirmed by watching `bmon -p eth0,eth1,bond0` during execution).
And with the entire route being able to carry nearly 1.8 Gbps, there's no surprise that different congestion algorithms don't affect single-stream performance in all scenarios.

We then note the huge difference between the BBR and CUBIC algorithms.
Because destinations A and B both have a very low BDP, any fluctuation in latency hits hard on CUBIC in forms of out-of-order packet deliveries, which reflects clearly in the difference of retransmitted packets and the Cwnd size.
In TLB mode, with only one active NIC, retransmission is kept low, but in RR mode it skyrocketed.

For destination C however, that's an entirely different case (zero retransmission) with its own reason:
There's enough BDP for the sender to raise Cwnd up to 8 MiB, but the receiver reports a window of only 4 MiB, so the entire transmission is limited by the receiver, not congestion or link load.

### Parallel streams

During the experiment, I found it very often that all 4 streams gets load-balanced onto one NIC in `balance-tlb` mode, so I had to re-run the tests multiple times to obtain the result where 4 streams are equally balanced onto both NICs.
Results from imbalanced stream distributions are discarded during retry.

For 4 parallel streams, the result looks much better:

| Dest | P | CC | Bitrate (RR) | Bitrate (TLB) | Retr (RR) | Retr (TLB) | Cwnd (RR) | Cwnd (TLB) |
| :--: | :--: | :--: | ---: | ---: | ---: | ---: | ---: | ---: |
| A | 4 | BBR | 1.79 Gbps | 1.77 Gbps | 41357 | 18 | 222 KB | 178 KB |
| A | 4 | CUBIC | 1.80 Gbps | 1.77 Gbps | 13254 | 82 | 48 KB | 306 KB |
| B | 4 | BBR | 1.79 Gbps | 1.72 Gbps | 61810 | 9368 | 237 KB | 236 KB |
| B | 4 | CUBIC | 1.77 Gbps | 1.74 Gbps | 15549 | 4243 | 31 KB | 174 KB |
| C | 4 | BBR | 1.70 Gbps | 1.82 Gbps | 185 | 0 | 4.04 MB | 3.84 MB |
| C | 4 | CUBIC | 1.74 Gbps | 1.82 Gbps | 20 | 17 | 2.91 MB | 2.89 MB |

The gap between RR and TLB no longer exists, and differences in retransmissions and Cwnd size can be attributed entirely to the CC algorithms themselves.
In particular, due to Cwnd falling under 4 MiB, or possibly just random network fluctuation, retransmission to destination C is observed for the first time.
It's also interesting to note that the difference in Cwnd size between BBR and CUBIC increased to 5x, compared to some 3 ~ 3.5x in single-stream case.

However, the numbers of retransmissions are lower by magnitudes in TLB bond mode than in RR mode.
I believe this is because the latencies to destinations A and B have very high variation compared to their means (averages), which will result in high number of reordered packets when packets from the same stream are distributed through two underlying interfaces.

## Bottom line

I did a set of rudimentary experiments in this article, and TCP upload is only a very generic use case.
For example, @TheRainstorm is running Sunshine streaming inside load-balanced WireGuard tunnel, and turning up forward error correction (FEC) level is one way to offset fluctuation and packet loss.
I've been running qBittorrent uploads under `balance-tlb` mode for months, and it's been very stable because qBittorrent uploads torrent content over many connections.

If anyone wants a more reliable multi-NIC bonding setup, I'd definitely recommend getting a capable switch and doing bonding in `802.3ad` (LACP) mode.
But for a small homelab, `balance-rr` + BBR would probably suffice for optimizing single-stream transmission speed, at the cost of some overhead on bandwidth.
