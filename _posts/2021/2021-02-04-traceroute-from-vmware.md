---
title: "Fix traceroute not showing intermediate results in a virtual machine on Windows"
tags: networking windows
redirect_from: /p/40
---

Today when I was running some networking diagnostics from an Ubuntu inside VMware Workstation, I noticed this strange result from [`mtr` (My Traceroute)][mtr]:

![MTR with all intermediate hops blank](/image/linux/traceroute-failure.png)

This doesn't look right. Googling around brought me to this page: [traceroute from Ubuntu just shows first and last hops on VMPlayer 3.1.4 - VMware Technology Network VMTN](https://communities.vmware.com/t5/VMware-Workstation-Player/traceroute-from-Ubuntu-just-shows-first-and-last-hops-on/m-p/1677263)

The answers in that thread mentioned two points:

- *On the other hand once I switched to bridge, everything works.*
- *What about the intermediary requests, well the answers come back but somehow they are blocked by the Windows firewall.*

I immediately realized that it's because **Windows Firewall blocked responses from the intermediate hops**.

## The answer

<div class="notice--primary" markdown="1">
#### <i class="fas fa-shield-check"></i> The short answer
{: .no_toc }

The responses from the intermediate routers aren't "expected" and are blocked off by Windows Firewall.
</div>

#### The long answer
{: .no_toc }

Windows Firewall has a built-in connection tracking mechanism, similar to that of Linux (conntrack). Since `mtr` sends [pings (ICMP Echo Requests)][ping] to the target host, Windows Firewall is expecting ICMP Echo Replies from the target host as the correct response. However, traceroute works by sending packets with TTL starting from 1 until it reaches the target host, and receiving "timed out" notices from the intermediate routers when the packet "dies from time". This creates two discrepancies:

- The responses are ICMP Time Exceeded packets, not Echo Replies.
- The responses come from the intermediate routers, not the target host.

This unfortunately somehow "broke" the connection tracking mechanism in Windows Firewall, and leads to the responses being blocked off by Windows Firewall by default.


## The solution

<div class="notice--warning" markdown="1">
#### <i class="fas fa-shield-check"></i> The short solution
{: .no_toc }

Just turn off Windows Firewall entirely. **You probably don't want to or shouldn't do this.** Read on for the complete and real solution.
</div>

The correct solution to this problem is to let the intermediary responses through Windows Firewall. To actually do this, we'll **create a new firewall rule that allows ICMP Time Exceeded packets to come in**. You can stop here now if you know how to configure Windows Firewall.

Step-by-step solution:

1. Open **Windows Defender Firewall with Advanced Security** (at least it's called as such on my Windows 10). This can be done in two ways:
    - Go to **Start** → **Windows Administrative Tools** → **Windows Defender Firewall with Advanced Security**
    - Or hit **<kbd><i class="fab fa-fw fa-windows" />Win</kbd>+<kbd>R</kbd>**, enter `WF.msc` and hit Enter.
2. Select **Inbound Rules** on the left and then **New Rule...** on the right.

   ![Screenshot](https://i.stack.imgur.com/m1suMs.png)

3. Follow the prompt to create a new rule. Select the following options for each step. Note that the desired options are selected by default in some steps so you can simply click **Next**.

    - Rule Type: **Custom**
    - Program: **All programs** (just click Next)
    - Protocol and Ports:
        - Protocol type: **ICMPv4**
        - *(Optional)* Internet Control Message Protocol (ICMP) settings: Click **Customize** → Select **Specific ICMP types** and tick **Time Exceeded**
    - Scope: **Any IP address** for both (just click Next)
    - Action: **Allow** (just click Next)
    - Profile: Select all (just click Next)
    - Name: **Core Networking - Time Exceeded (ICMPv4-In)** (apparently just any name you prefer)
  
   Click **Finish** and you should immediately see intermediate hops if you're using `mtr`. For example:

   ![MTR correctly functioning](/image/linux/traceroute-ok.png)

4. *(Optional)* Repeat the above steps but select **ICMPv6** for *Protocol type* if you want to enable IPv6 traceroute. Don't forget to give it a different name (e.g. *(ICMPv6-In)* at the end).

    - In my case there's already a built-in rule named **Core Networking - Time Exceeded (ICMPv6-In)** which is even enabled by default. If you find it there, you can simply enable it.

### Bonus

If you want to make your rule *more solid* and *look* "canonical", you can add it to the built-in system group **Core Networking** with the help of PowerShell.

```powershell
$rule = Get-NetFirewallRule -DisplayName "Core Networking - Time Exceeded (ICMPv4-In)"
$rule.Group = "Core Networking"
$rule | Set-NetFirewallRule
```

Your new rule will look like this after running the above commands. You may need to restart the Windows Firewall window to see changes.

![New Rule](/image/windows/core-networking-time-exceeded-icmpv4-in.png)

---

This article was originally written as [an answer on Super User][sa].


  [mtr]: https://en.wikipedia.org/wiki/MTR_(software)
  [ping]: https://en.wikipedia.org/wiki/Ping_(networking_utility)#Echo_request
  [sa]: https://superuser.com/a/1623001/688600
