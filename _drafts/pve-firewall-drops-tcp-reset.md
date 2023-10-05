---
title: "Debugging Proxmox VE Firewall Dropping TCP Reset Packets"
tags: linux networking proxmox-ve
redirect_from: /p/61
---

A few days back when I was setting up a new VM to host some extra websites, I noticed an unexpected Nginx error page. As I don't administer the new websites, I just added reverse proxy rules on the gateway Nginx server, and deferred the actual configuration to whoever is in charge of them.

When I reviewed my edited Nginx configuration and tried visiting the new website, I received a 504 Gateway Timeout error after `curl` hung for a minute. Knowing that the web server had yet to be set up, I was expecting a 502 Bad Gateway error. I quickly recalled the conditions for Nginx to return these specific errors: 502 if the upstream server is immediately known down, and 504 if the upstream server is up but not responding.

Since the actual web application hadn't been set up yet, the new VM should have nothing listening on the configured ports. Consequently, the kernel should immediately respond with a TCP Reset for any incoming connections. To verify this, I ran `tcpdump` on both sides to check if the TCP reset packets actually came out. To my surprise, the packets were indeed sent out from the new VM, but the gateway server received nothing. So there was certainly something wrong with the firewall. I took a glance at the output of `pve-firewall compile`. They were very structured and adequately easy to understand, but I couldn't immediately identify anything wrong. Things were apparently more complicated than I had previously anticipated.

## Searching for information {#searching}

As usual, the first thing to try is Googling. Searching for `pve firewall tcp reset` brought [this post on Proxmox Forum][56300] as the first result. Their symptoms were precisely the same as mine:

  [56300]: https://forum.proxmox.com/threads/tcp-rst-packets-dropped-by-pve-firewall.56300/

> - Assume we have a service running on TCP port 12354
> - Clients can communicate with it while running
> - While service is down, clients recieved "Connection timed out" (no answer) even if OS send TCP RST packets:
>
> \[...\]
>
> However, these RST packets are dropped somewhere in PVE firewall.  
> On the VM options :
>
> - Firewall > Options > Firewall = No, Has no effect
> - Firewall > Options > \* Policy = ACCEPT, Has no effect (even with NO rule in active for this VM)
> - Hardware > Network Device > `firewall=0`, allows packets RST to pass!

I gave the last suggestion a try, and it worked! I could now see connections immediately reset on the gateway server, and Nginx started producing 502 errors. But I was still confused why this happened in the first place. The first thread contained nothing else useful, so I continued scanning through other search results and noticed [another post][55634] about another seemingly unrelated problem, with a plausible solution:

  [55634]: https://forum.proxmox.com/threads/turning-on-the-pve-firewall-stops-vm-lxc-connectivity.55634/#post-261316

> \[...\], and the fix was just to add the `nf_conntrack_allow_invalid: 1` in the `host.fw` for each node - I didn't have to do anything other than that.

That seemed understandable to me, so I gave it a try as well, and to my pleasure, it also worked.

Regrettably, useful information ceased to exist online beyond this, and it was far from painting the whole picture. So anything further would have to be uncovered on my own.

## Reviewing information {#reviewing}

I reviewed the two helpful workarounds and made myself abundantly clear about their effects:

- Disabling the firewall on the virtual network device stops PVE from bridging the interface an extra time, as shown in the following diagram:

    ![PVE Firewall Diagram](/image/pve-firewall/pve-fwbr.png)

- Adding `nf_conntrack_allow_invalid: 1` removes one single iptables rule:

    ```shell
    -A PVEFW-FORWARD -m conntrack --ctstate INVALID -j DROP
    ```

I couldn't figure out how the first difference was relevant, but the second one provided an important clue: The firewall was dropping TCP Reset packets because conntrack considered them invalid.

Conntrack (**conn**ection **track**ing) is a Linux kernel subsystem that tracks network connections and aids in stateful packet inspection and network address translation. The first packet of a connection is considered "NEW", and subsequent packets from the same connection are considered "ESTABLISHED", including the TCP Reset packet when it's first seen, which causes conntrack to delete the connection entry.

There was still yet anything obvious, so time to start debugging.

## Inspecting packet captures {#tcpdump}

I ran `tcpdump -ni any host 172.31.0.2 and host 172.31.1.11 and tcp` on the PVE host to capture packets between the two VMs. This is what I got (output trimmed):

```text
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
16:33:11.911184 veth101i1 P   IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911202 fwln101i1 Out IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911203 fwpr101p1 P   IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911206 fwpr811p0 Out IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911207 fwln811i0 P   IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911213 tap811i0  Out IP 172.31.0.2.50198 > 172.31.1.11.80: Flags [S], seq 3404503761, win 64240
16:33:11.911262 tap811i0  P   IP 172.31.1.11.80 > 172.31.0.2.50198: Flags [R.], seq 0, ack 3404503762, win 0, length 0
16:33:11.911267 fwln811i0 Out IP 172.31.1.11.80 > 172.31.0.2.50198: Flags [R.], seq 0, ack 1, win 0, length 0
16:33:11.911269 fwpr811p0 P   IP 172.31.1.11.80 > 172.31.0.2.50198: Flags [R.], seq 0, ack 1, win 0, length 0
^C
9 packets captured
178 packets received by filter
0 packets dropped by kernel
```

The first thing to notice is the ACK number. After coming from `tap811i0`, it suddenly became 1 with no apparent reason. I struggled on this for a good while and temporarily put it aside.

Adding `nf_conntrack_allow_invalid: 1` to the firewall options and capturing packets again, I got the following:

```text
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
16:46:15.243002 veth101i1 P   IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243015 fwln101i1 Out IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243016 fwpr101p1 P   IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243020 fwpr811p0 Out IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243021 fwln811i0 P   IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243027 tap811i0  Out IP 172.31.0.2.58784 > 172.31.1.11.80: Flags [S], seq 301948896, win 64240
16:46:15.243076 tap811i0  P   IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 301948897, win 0, length 0
16:46:15.243081 fwln811i0 Out IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 1, win 0, length 0
16:46:15.243083 fwpr811p0 P   IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 1, win 0, length 0
16:46:15.243086 fwpr101p1 Out IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 1, win 0, length 0
16:46:15.243087 fwln101i1 P   IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 1, win 0, length 0
16:46:15.243090 veth101i1 Out IP 172.31.1.11.80 > 172.31.0.2.58784: Flags [R.], seq 0, ack 1, win 0, length 0
^C
```

This time while the ACK number was still wrong, the RST packet somehow got through. Ignoring the ACK numbers for now, the output suggested that the RST packet was dropped between `fwpr811p0 P` and `fwln811i0 Out`. That was the main bridge `vmbr0`. All right then, that was where the `PVEFW-FORWARD` chain kicked in, so at this point the RST packet was `--ctstate INVALID`. Everything was logical up to this point.

So how about disabling firewall for the interface on VM 811?

```text
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
17:19:01.812030 veth101i1 P   IP 172.31.0.2.39734 > 172.31.1.11.80: Flags [S], seq 1128018611, win 64240
17:19:01.812045 fwln101i1 Out IP 172.31.0.2.39734 > 172.31.1.11.80: Flags [S], seq 1128018611, win 64240
17:19:01.812046 fwpr101p1 P   IP 172.31.0.2.39734 > 172.31.1.11.80: Flags [S], seq 1128018611, win 64240
17:19:01.812051 tap811i0  Out IP 172.31.0.2.39734 > 172.31.1.11.80: Flags [S], seq 1128018611, win 64240
17:19:01.812178 tap811i0  P   IP 172.31.1.11.80 > 172.31.0.2.39734: Flags [R.], seq 0, ack 1128018612, win 0, length 0
17:19:01.812183 fwpr101p1 Out IP 172.31.1.11.80 > 172.31.0.2.39734: Flags [R.], seq 0, ack 1, win 0, length 0
17:19:01.812185 fwln101i1 P   IP 172.31.1.11.80 > 172.31.0.2.39734: Flags [R.], seq 0, ack 1, win 0, length 0
17:19:01.812190 veth101i1 Out IP 172.31.1.11.80 > 172.31.0.2.39734: Flags [R.], seq 0, ack 1, win 0, length 0
^C
```

This time `fwbr811i0` was missing, and the RST packet didn't get dropped at `vmbr0`. I was left totally confused.

I decided to sort out the ACK number issue, but ended up asking my friends for help. It turned out this was well documented in `tcpdump(8)`:

> -S  
> --absolute-tcp-sequence-numbers  
> Print absolute, rather than relative, TCP sequence numbers.

This certainly came out unexpected, but at least I was assured there was nothing wrong with the ACK numbers.

Up to now, that's one more step forward, and a small conclusion:

- At the point the RST packet reached `vmbr0`, it was already `--ctstate INVALID`.

But how? As far as I knew, when the RST packet came out, it should still be considered part of the connection, and thus should be `--ctstate ESTABLISHED`. I was still missing something.

Time to investigate conntrack.

## Inspecting conntrack {#conntrack}

`conntrack` is the tool to inspect and modify conntrack entries. I ran `conntrack -L` to list all entries, only to realize it's inefficient. So instead, I ran `conntrack -E` to watch for "events" in real time, so that I could compare the output with `tcpdump`. Except that the entire connection concluded so quickly that I couldn't identify anything.

I had to add artificial delays to the packets to clearly separate each hop that the RST packet goes through:

```shell
tc qdisc add dev tap811i0 root netem delay 200ms
tc qdisc add dev fwln811i0 root netem delay 200ms
```

I also tuned the output on both sides to show the timestamp in a consistent format. For conntrack, `-o timestamp` produced Unix timestamps (which is the only supported format), so for `tcpdump` I also resorted to `-tt` to show Unix timestamps as well.

```shell
conntrack -E -o timestamp -s 172.31.0.2 -d 172.31.1.11
tcpdump -ttSni any host 172.31.0.2 and host 172.31.1.11 and tcp
```

Now I could watch the outputs on two separate tmux panes. The problem immediately emerged (blank lines added for readability):

```text
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
1696412047.886575 veth101i1 P   IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]
1696412047.886592 fwln101i1 Out IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]
1696412047.886594 fwpr101p1 P   IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]
1696412047.886599 fwpr811p0 Out IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]
1696412047.886600 fwln811i0 P   IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]

1696412048.086620 tap811i0  Out IP 172.31.0.2.47066 > 172.31.1.11.80: Flags [S]
1696412048.086841 tap811i0  P   IP 172.31.1.11.80 > 172.31.0.2.47066: Flags [R.]

1696412048.286919 fwln811i0 Out IP 172.31.1.11.80 > 172.31.0.2.47066: Flags [R.]
1696412048.286930 fwpr811p0 P   IP 172.31.1.11.80 > 172.31.0.2.47066: Flags [R.]
^C
```

```text
[1696412047.886657]         [NEW] tcp      6 120 SYN_SENT src=172.31.0.2 dst=172.31.1.11 sport=47066 dport=80 [UNREPLIED] src=172.31.1.11 dst=172.31.0.2 sport=80 dport=47066
[1696412048.086899]     [DESTROY] tcp      6 119 CLOSE src=172.31.0.2 dst=172.31.1.11 sport=47066 dport=80 [UNREPLIED] src=172.31.1.11 dst=172.31.0.2 sport=80 dport=47066
```

The artificial delays and the timestamps were absolutely useful: It was clear that the corresponding conntrack connection was destroyed as soon as the RST packet passed through `fwbr811i0`, before it came out via `fwln811i0`. When it reached `vmbr0`, the connection was already gone, and the RST packet was considered invalid.

It also became explainable how `firewall=0` on the virtual network device remedied the issue: It removed an extra bridge `fwbr811i0`, so the connection stayed alive when the RST packet reached `vmbr0`, at which point a previous rule for `--ctstate ESTABLISHED` gave an `ACCEPT` verdict. While it was still `INVALID` when passing through `fwbr101i1`, there was no rule concerning `--ctstate` at play, so it slipped through this stage with no problem.

After double-checking the intention of the extra `fwbr*` bridge, I drew the conclusion that **this must be a bug with PVE Firewall**. I reported it on the Proxmox VE bug tracker as [#4983][4983], and soon received a reply:

> Thank you for the detailed write-up!
>
> This is a known limitation for our kind of firewall setup, since the conntrack is shared between all interfaces on the host.
>
> \[...\]
>
> If you know of any other way to avoid this happening, other than using conntrack zones, I'd be happy to take a look.

So they admitted that this was a limitation but without a satisfactory solution. Guess I'm still on my own, though.

## Finding the solution {#solution}

The actual problem is, when passing through `fwbr811i0`, the RST packet isn't supposed to be processed by conntrack by then. There is no `sysctl` option to disable conntrack on a specific interface (or even just all bridges altogether), but at the right time the rarely-used `raw` table came to my mind. It didn't take long to work this out:

```shell
iptables -t raw -A PREROUTING -i fwbr+ -j CT --notrack
```

After verifying this is the intended solution, I added it as a reply to the bug report. At the time of writing this blog post, the bug report is still open, but I'm sure it's to be resolved soon.

## Conclusion

Debugging Linux networking has always been a pain for its lack of proper tools and its complexity. Most of the times even reading and understanding packet captures requires immense knowledge of the protocols and all the involved components, as well as scrutinizing every single detail available. Sometimes it's even necessary to think outside the box but fortunately not today.

Also worth mentioning is that it's easy to suspect the fault of another piece of software, but detailed investigation is always necessary to actually lay the blame.

Just as a late reminder, useful bug reports always require detailed information and solid evidence. Glad I was able to have them at hand this time.


  [4983]: https://bugzilla.proxmox.com/show_bug.cgi?id=4983
