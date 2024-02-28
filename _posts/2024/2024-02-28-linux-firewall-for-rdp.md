---
title: My firewall solution for RDP
tags: linux windows networking
redirect_from: /p/65
toc: false
---

Today I stumbled upon [this V2EX post](https://www.v2ex.com/t/1019147) (Simplified Chinese) where the OP shared their PowerShell implementation of a "makeshift fail2ban" for RDP ([their GitHub repository](https://github.com/Qetesh/rdpFail2Ban)). Their script looked very clean and robust, but needless to say, it is unnecessarily difficult on Windows. So on this rare (maybe?) occasion I decide to share my firewall for securing RDP access to my Windows hosts.

**None** of my Windows hosts (PCs and VMs) has their RDP port exposed to the public internet directly, and they're all connected to my mesh VPN (which is out of scope for this blog article). My primary public internet entry gateway for the intranet runs Debian with fully manually configured iptables-based firewall, and I frequently work on it through SSH.

My goal is to expose the RDP port only to myself. There are a few obvious solutions eliminated for different reasons:

- **VPN** is inconvenient as I don't want to connect to VPN just for RDP when I don't need it otherwise.
- **SSH port forwarding** is not performant for two things: Double-encryption and lack of UDP support.

The question arises that if SSH access is sufficiently convenient, why not use it as an authentication and authorization mechanism? So I came up with this:

- A pre-configured iptables rule set to allow RDP access from a specific IP set. For example:

  ```shell
  *filter
  :FORWARD DROP
  -A FORWARD -d 192.0.2.1 -p tcp --dport 3389 -m set --set ibug -j ACCEPT

  *nat
  -A RDPForward -p tcp --dport 3389 -j DNAT --to-destination 192.0.2.1:3389
  -A RDPForward -p udp --dport 3389 -j DNAT --to-destination 192.0.2.1:3389
  ```

- A way to keep the client address in the set for the duration of the SSH session. I use SSH user rc file to proactively refresh it:

  ```shell
  #!/bin/bash
  # rwxr-xr-x ~/.ssh/rc

  if [ -z "$BASH" ]; then
    exec /bin/bash -- "$0" "$@"
    exit 1
  fi

  _ssh_client="${SSH_CONNECTION%% *}"
  _ppid="$(ps -o ppid= $(ps -o ppid= $PPID))"

  nohup ~/.local/bin/_ssh_refresh_client "$_ssh_client" "$_ppid" &>/dev/null & exit 0
  ```

  ```shell
  #!/bin/sh
  # rwxr-xr-x ~/.local/bin/_ssh_refresh_client
  _ssh_client="$1"
  _ppid="$2"
  while kill -0 "$_ppid" 2>/dev/null; do
    sudo ipset -exist add ibug "$_ssh_client" timeout 300
    sleep 60
  done
  exit 0
  ```

The idea is to refresh (`ipset add` with timeout) the IPset entry as long as the SSH session remains. When SSH disconnects, the script stops refreshing and IPset will clean it up after the specified time.

To determine the presence of the associated SSH session, the scripts finds the PID of the "session manager process". The "parent PID" is read twice because `sshd` double-forks. The client address is conveniently provided in the environment variable, so putting all these together yields precisely what I need.

The only caveat is the use of `sudo`, as `ipset` requires `CAP_NET_ADMIN` for interacting with the kernel network stack. It's certainly possible to write an SUID binary as a wrapper, but for me configuring passwordless sudo for the `ipset` command satisfies my demands.

So now whenever I need to RDP to my computer through this forwarded port on the public internet, I can just SSH into the gateway and it'll automatically grant me 5 minutes of RDP access from this specific network. All traffic forwarding is done in the kernel with no extra encapsulation or encryption, ensuring the best possible performance for both the endpoints and the gateway router itself.
