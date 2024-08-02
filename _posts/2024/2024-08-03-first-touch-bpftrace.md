---
title: "Why my IPv4 gets stuck? - Debugging network issues with bpftrace"
tags: linux networking
redirect_from: /p/71
---

I run a Debian-based software router on my home network. It's connected to multiple ISPs, so I have some policy routing rules to balance the traffic between them. Some time ago, I noticed that the IPv4 connectivity got stuck intermittently when it didn't use to, while IPv6 was working fine. It's also interesting that the issue only happened with one specific ISP, in the egress direction, and only a few specific devices were affected.

At first I suspected the ISP's equipment, but a clue quickly dismissed that suspicion: Connection to the same ISP worked fine when initiated from the router itself, as well as many other unaffected devices. So the issue must be within the router.

As usual, every network debugging begins with a packet capture. I start `tcpdump` on both the LAN interface and the problematic WAN interface, then try `curl`-ing something from an affected device. Packet capture shows a few back-and-forth packets, then the device keeps sending packets but the router doesn't forward them to the WAN interface anymore. Time for a closer look.

## Identifying the issue

On an affected device, `curl` gets stuck somewhere in the middle:

```console
$ curl -vso /dev/null https://www.cloudflare.com/
*   Trying 104.16.124.96:443...
* Connected to www.cloudflare.com (104.16.124.96) port 443 (#0)
* ALPN: offers h2,http/1.1
} [5 bytes data]
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
} [512 bytes data]
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
{ [5 bytes data]
* TLSv1.3 (IN), TLS handshake, Server hello (2):
{ [122 bytes data]
^C
```

`tcpdump` shows nothing special:

```console
# tcpdump -ni any 'host 104.16.124.96 and tcp port 443'
02:03:47.403905 lan0 In  IP 172.17.0.2.49194 > 104.16.124.96.443: Flags [S], seq 1854398703, win 65535, options [mss 1460,sackOK,TS val 1651776756 ecr 0,nop,wscale 10], length 0
02:03:47.403956 ppp0 Out IP 10.250.193.4.49194 > 104.16.124.96.443: Flags [S], seq 1854398703, win 65535, options [mss 1432,sackOK,TS val 1651776756 ecr 0,nop,wscale 10], length 0
02:03:47.447663 ppp0 In  IP 104.16.124.96.443 > 10.250.193.4.49194: Flags [S.], seq 1391350792, ack 1854398704, win 65535, options [mss 1460,sackOK,TS val 141787839 ecr 1651776756,nop,wscale 13], length 0
02:03:47.447696 lan0 Out IP 104.16.124.96.443 > 172.17.0.2.49194: Flags [S.], seq 1391350792, ack 1854398704, win 65535, options [mss 1460,sackOK,TS val 141787839 ecr 1651776756,nop,wscale 13], length 0
02:03:47.447720 lan0 In  IP 172.17.0.2.49194 > 104.16.124.96.443: Flags [.], ack 1, win 64, options [nop,nop,TS val 1651776800 ecr 141787839], length 0
02:03:47.452705 lan0 In  IP 172.17.0.2.49194 > 104.16.124.96.443: Flags [P.], seq 1:518, ack 1, win 64, options [nop,nop,TS val 1651776804 ecr 141787839], length 517
02:03:47.452751 ppp0 Out IP 10.250.193.4.49194 > 104.16.124.96.443: Flags [P.], seq 1:518, ack 1, win 64, options [nop,nop,TS val 1651776804 ecr 141787839], length 517
02:03:47.496507 ppp0 In  IP 104.16.124.96.443 > 10.250.193.4.49194: Flags [.], ack 518, win 9, options [nop,nop,TS val 141787888 ecr 1651776804], length 0
02:03:47.496527 lan0 Out IP 104.16.124.96.443 > 172.17.0.2.49194: Flags [.], ack 518, win 9, options [nop,nop,TS val 141787888 ecr 1651776804], length 0
02:03:47.498147 ppp0 In  IP 104.16.124.96.443 > 10.250.193.4.49194: Flags [P.], seq 1:2737, ack 518, win 9, options [nop,nop,TS val 141787890 ecr 1651776804], length 2736
02:03:47.498165 lan0 Out IP 104.16.124.96.443 > 172.17.0.2.49194: Flags [P.], seq 1:2737, ack 518, win 9, options [nop,nop,TS val 141787890 ecr 1651776804], length 2736
02:03:47.498175 lan0 In  IP 172.17.0.2.49194 > 104.16.124.96.443: Flags [.], ack 2737, win 70, options [nop,nop,TS val 1651776850 ecr 141787890], length 0
02:03:47.498195 ppp0 In  IP 104.16.124.96.443 > 10.250.193.4.49194: Flags [P.], seq 2737:3758, ack 518, win 9, options [nop,nop,TS val 141787890 ecr 1651776804], length 1021
02:03:47.498228 ppp0 Out IP 10.250.193.4.49194 > 104.16.124.96.443: Flags [R], seq 1854399221, win 0, length 0
^C
711 packets captured
720 packets received by filter
0 packets dropped by kernel
```

Considering the complexity of the policy routing, I tried inspecting conntrack status in parallel. Nothing unusual there either, until I tried matching conntrack events with `tcpdump`:

```console
# conntrack -E -s 172.17.0.2 -p tcp --dport 443 2>/dev/null | ts %.T
02:03:47.404103     [NEW] tcp      6 120 SYN_SENT src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 [UNREPLIED] src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194
02:03:47.447748  [UPDATE] tcp      6 60 SYN_RECV src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194 mark=48
02:03:47.447843 [DESTROY] tcp      6 432000 ESTABLISHED src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194 [ASSURED] mark=48
02:03:47.452798     [NEW] tcp      6 300 ESTABLISHED src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 [UNREPLIED] src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194
02:03:47.496572  [UPDATE] tcp      6 300 src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194 mark=48
02:03:47.498195  [UPDATE] tcp      6 300 src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194 [ASSURED] mark=48
02:03:47.498243 [DESTROY] tcp      6 432000 ESTABLISHED src=172.17.0.2 dst=104.16.124.96 sport=49194 dport=443 src=104.16.124.96 dst=10.250.193.4 sport=443 dport=49194 [ASSURED] mark=48
^C
```

With `ts` (from [`moreutils`][moreutils]) adding timestamps to conntrack events, I can see that the conntrack entry is destroyed right after (+123μs) the second packet comes in from the device. Subsequent packets causes (+93μs) the same conntrack entry to be recreated, so `curl` could somehow complete the SSL handshake to a point where it only sends one packet and nothing afterwards for the connection to be recreated for a third time.

  [moreutils]: https://packages.debian.org/stable/moreutils

Clearly the second packet should be considered `ESTABLISHED` by conntrack and makes no sense to trigger a `DESTROY` event. I'm at a loss here and start trying random things hoping to find a clue. I tried downgrading the kernel to 5.10 (from Bullseye) and upgrading to 6.9 (from Bookworm backports), but nothing changed, eliminating the possibility of a kernel bug.

After scrutinizing my firewall rules, I noticed a small difference between IPv4 and IPv6 rules:

```shell
# rules.v4
*nat
# ...
-A POSTROUTING -o ppp+ -j MASQUERADE
COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
# ...
-A PREROUTING -j CONNMARK --restore-mark
-A PREROUTING -m mark ! --mark 0 -j ACCEPT
#A PREROUTING -m conntrack --ctstate NEW,RELATED -j MARK --set-xmark 0x100/0x100
-A PREROUTING -m mark --mark 0/0xff -j ExtraConn
-A PREROUTING -m mark --mark 0/0xff -j IntraConn
-A PREROUTING -m mark --mark 0/0xff -j MARK --set-xmark 0x30/0xff
-A PREROUTING -j CONNMARK --save-mark
# ...
-A ExtraConn -i ppp0 -j MARK --set-xmark 0x30/0xff
# ...
-A IntraConn -s 172.17.0.2/32 -j iBugOptimized
# ...
-A iBugOptimized -j MARK --set-xmark 0x36/0xff
-A iBugOptimized -j ACCEPT
COMMIT
```

However, `rules.v6` is missing the last rule in `iBugOptimized`, and IPv6 is somehow exempt from the conntrack issue. Removing this extra `ACCEPT` rule from `rules.v4` fully restores the connectivity. So this is certainly the cause, but how is it related to the actual issue?

## Investigation

*I know there are some decent tools on GitHub that aids in debugging iptables, which is notorious for its complexity. But since I wrote the entire firewall rule set and am still maintaining it by hand, I'm going for the hard route of watching and understanding every single rule.*

The difference for that single `ACCEPT` rule is, it skips the `--save-mark` step, so the assigned firewall mark is not saved to its corresponding conntrack entry. When a reply packet comes in, conntrack has nothing for the `--restore-mark` step, so the packet gets assigned the "default" mark of `0x30` and *then* this value gets saved. I should have noticed the wrong conntrack mark earlier, as `conntrack -L` clearly showed a mark of 48 instead of the intended 54 (`0x36` from `iBugOptimized`). This narrows the cause down to a discrepancy between the packet mark and the conntrack mark.

Firewall marks are a more flexible way to implement slightly complicated policy-based routing, as it defers the routing decision to the `mangle/PREROUTING` chain instead of the single-chain global routing rules. In my case, every ISP gets assigned a fwmark routing rule like this:

```text
9:      from all fwmark 0x30/0xff lookup eth0 proto static
9:      from all fwmark 0x31/0xff lookup eth1 proto static
9:      from all fwmark 0x36/0xff lookup ppp0 proto static
```

Presumably, subsequent packets from the same connection should be routed to `eth0` because it has the mark `0x30` restored from conntrack entry. This is not the case, however, as `tcpdump` shows nothing on `eth0` and everything on `ppp0`.

Unless there's some magic in the kernel for it to decide to destroy a connection simply for a packet mark mismatch, this is not close enough to the root cause. Verifying the magic is relatively easy:

```shell
iptables -I PREROUTING -s 172.17.0.2/32 -j Test
iptables -A Test -m conntrack --ctstate NEW -j MARK --set-xmark 0x36/0xff
iptables -A Test -m conntrack --ctstate ESTABLISHED -j MARK --set-xmark 0x30/0xff
```

This time, even if `conntrack` shows no mark (i.e. zero) on the connection, the packets are still routed correctly to `ppp0`, and curl gets stuck as the same place as before. So the kernel doesn't care about the conntrack mark at all.

Unfortunately, this is about as far as userspace inspection can go. I need to find out why exactly the kernel decides to destroy the conntrack entry.

## `bpftrace` comes in

I've seen professional kernel network developers extensively running `bpftrace` to debug network issues (THANK YOU to the guy behind the Telegram channel *Welcome to the Black Parade*), so I'm giving it a try.

First thing is to figure out what to hook. Searching through Google did not reveal a trace point for conntrack events, but I get to know about the conntrack path. With help from ChatGPT, I begin with `kprobe:nf_ct_delete` and putting together all struct definitions starting from `struct nf_conn`:

```c
#include <linux/socket.h>
#include <net/netfilter/nf_conntrack.h>

kprobe:nf_ct_delete
{
    // The first argument is the struct nf_conn
    $ct = (struct nf_conn *)arg0;

    // Check if the connection is for IPv4
    if ($ct->tuplehash[0].tuple.src.l3num == AF_INET) {
        $src_ip = $ct->tuplehash[0].tuple.src.u3.ip;
        $dst_ip = $ct->tuplehash[0].tuple.dst.u3.ip;
        printf("Conntrack destroyed (IPv4): src=%s dst=%s\n",
                ntop($src_ip), ntop($dst_ip));
    }
}
```

Seems all good, except it won't compile:

```text
ERROR: Can not access field 'u3' on expression of type 'none'
        $dst_ip = $ct->tuplehash[0].tuple.dst.u3.ip;
                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

After another half-hour of struggling and bothering with ChatGPT, I gave up trying to access the destination tuple, and thought I'd be fine with inspecting the stack trace:

```c
#include <linux/socket.h>
#include <net/netfilter/nf_conntrack.h>

kprobe:nf_ct_delete
{
    // The first argument is the struct nf_conn
    $ct = (struct nf_conn *)arg0;

    // Check if the connection is for IPv4
    if ($ct->tuplehash[0].tuple.src.l3num == AF_INET) {
        $tuple_orig = $ct->tuplehash[0].tuple;
        $src_ip = $tuple_orig.src.u3.ip;
        $src_port_n = $tuple_orig.src.u.all;
        $src_port = ($src_port_n >> 8) | (($src_port_n << 8) & 0x00FF00);
        if ($src_ip != 0x020011ac) {
            return;
        }
        $mark = $ct->mark;
        printf("Conntrack destroyed (IPv4): src=%s sport=%d mark=%d\n",
                ntop($src_ip), $src_port, $mark);

        printf("%s\n", kstack());
    }
}
```

Noteworthy is that I have to filter the connections in the program, otherwise my screen gets flooded with unrelated events.

The output comes promising:

```text
Attaching 1 probe...
Conntrack destroyed (IPv4): src=172.17.0.2 sport=39456 mark=0 proto=6

    nf_ct_delete+1
    nf_nat_inet_fn+188
    nf_nat_ipv4_out+80
    nf_hook_slow+70
    ip_output+220
    ip_forward_finish+132
    ip_forward+1296
    ip_rcv+404
    __netif_receive_skb_one_core+145
    __netif_receive_skb+21
    netif_receive_skb+300
    ...
```

Reading the source code from the top few functions of the call stack:

```c
// net/netfilter/nf_nat_proto.c

static unsigned int
nf_nat_ipv4_out(void *priv, struct sk_buff *skb,
                const struct nf_hook_state *state)
{
#ifdef CONFIG_XFRM
    const struct nf_conn *ct;
    enum ip_conntrack_info ctinfo;
    int err;
#endif
    unsigned int ret;

    ret = nf_nat_ipv4_fn(priv, skb, state); // <-- call to nf_nat_ipv4_fn
#ifdef CONFIG_XFRM
    if (ret != NF_ACCEPT)
        return ret;
```

```c
// net/netfilter/nf_nat_proto.c

static unsigned int
nf_nat_ipv4_fn(void *priv, struct sk_buff *skb,
               const struct nf_hook_state *state)
{
    // ...

    return nf_nat_inet_fn(priv, skb, state);
}
```

```c
// net/netfilter/nf_nat_core.c

unsigned int
nf_nat_inet_fn(void *priv, struct sk_buff *skb,
               const struct nf_hook_state *state)
{
    // ...
        if (nf_nat_oif_changed(state->hook, ctinfo, nat, state->out))
            goto oif_changed;
    // ...

oif_changed:
    nf_ct_kill_acct(ct, ctinfo, skb);
    return NF_DROP;
}
```

As far as function inlining goes, there's only one way `nf_nat_inet_fn` calls into `nf_ct_delete`, which is through `nf_ct_kill_acct`. And the only reason for that is `nf_nat_oif_changed`.

## Conclusion

Now everything makes sense. With a badly placed `ACCEPT` rule, the conntrack connection gets saved a different mark than desired, and then destroyed because subsequent packets are routed differently for having the wrong mark. The timestamp difference of related events also roughly matches up the distance of the code path. It also must be a NAT'ed connection, as this way of `nf_ct_delete` is only reachable when the packet is about to be sent to the egress interface.
