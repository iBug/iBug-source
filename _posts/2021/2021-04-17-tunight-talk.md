---
layout: remark
title: Tunight talk
description: Slides for my talk at Tunight
redirect_from: /p/42
hidden: true
---

class: center, middle

# Tech Talk

[iBug](//ibugone.com)
<br>
[LUG @ USTC](https://lug.ustc.edu.cn)
<br>
April 17, 2021

---

## Overview

- Intranet of USTCLUG
- Auto SSL certificate
- Vlab
- Miscellaneous

---

## Intranet of USTCLUG

- Multiple cloud and on-premises servers in different datacenters
- Public and internal services
  - Public: Mirrors, Auth DNS, Homepage
  - Internal: LDAP, Mail gateway, InfluxDB

--

<!-- -->
- Layer 2 overlay network
  - [Tinc VPN](//www.tinc-vpn.org)

---

## Tinc VPN

- Configured in switch mode
- Mesh layout
- **Bridged within one datacenter (cluster)**
- Secured over the Internet

---

<iframe src="https://www.draw.io/?lightbox=1&highlight=0000ff&edit=_blank&layers=1&nav=1&title=LUG%20Network.html#Uhttps%3A%2F%2Fdrive.google.com%2Fa%2F0x01.me%2Fuc%3Fid%3D1WAROAPB8ThTkIjMyFnGvtGgbH-TV4FWh%26export%3Ddownload" frameborder="0" style="width: 100%; height: 100%;"></iframe>

---

layout: true

## Automatic SSL certificate issue &amp; renewal

---

---

 Compliance:

- Our friend sponsored us a Japan VPS so we resolve most of `ustclug.org` (from outside USTCnet) to it
  - We resolve `ustclug.org` to USTCnet when source is also in USTCnet

<!-- -->
- USTC Mirrors has 4 ISP connections (CERNET, Telecom, Mobile, Unicom) and we want to route users by source

--

<!-- -->
- Solution: Self-hosted Bind9 server
  - Return different answers based on source IP (views)

---

- Solution: Self-hosted Bind9 server
  - Return different answers based on source IP (views)
- Custom authoritative DNS servers

--
- Git-based DNS management
- Integration into existing applications?
  - We have no easy-to-use API

---

layout: true

## Automatic SSL certificate issue &amp; renewal

Use an existing API!

---

---

```shell
# apt list ~npython3-certbot-dns
python3-certbot-dns-cloudflare    - Doesn't support sub-zones
python3-certbot-dns-digitalocean  - [OK]
python3-certbot-dns-dnsimple      - Paid
python3-certbot-dns-gandi         - Doesn't support sub-zones
python3-certbot-dns-gehirn        - [Couldn't determine]
python3-certbot-dns-google        - Doesn't support sub-zones
python3-certbot-dns-linode        - No account, couldn't determine
python3-certbot-dns-ovh           - Could not register account
python3-certbot-dns-rfc2136       - Performance?
python3-certbot-dns-route53       - Paid
python3-certbot-dns-sakuracloud   - Could not register account
```

`acme.sh`?

---

```dns
_acme-challenge.lug.ustc.edu.cn.     600 IN CNAME  lug.ssl-digitalocean.ustclug.org.
_acme-challenge.ustclug.org.         600 IN CNAME  lug.ssl-digitalocean.ustclug.org.
_acme-challenge.proxy.ustclug.org.   600 IN CNAME  lug.ssl-digitalocean.ustclug.org.
_acme-challenge.mirrors.ustc.edu.cn. 600 IN CNAME  mirrors.ssl-digitalocean.ustclug.org.
```

```dns
ssl-digitalocean.ustclug.org.  86400 IN NS  ns1.digitalocean.com.
                               86400 IN NS  ns2.digitalocean.com.
                               86400 IN NS  ns3.digitalocean.com.
```

---

```shell
acme.sh --issue \
  --dns dns_dgon \
  --domain-alias lug.ssl-digitalocean.ustclug.org \
  -d lug.ustc.edu.cn \
  -d \*.lug.ustc.edu.cn \
  -d ustclug.org \
  -d \*.ustclug.org \
  -d \*.proxy.ustclug.org \
  --cert-file cert/lug/cert.pem \
  --key-file cert/lug/privkey.pem \
  --fullchain-file cert/lug/fullchain.pem
```

---

```shell
acme.sh --issue \
  --dns dns_dgon \
  --domain-alias mirrors.ssl-digitalocean.ustclug.org \
  -d mirrors.ustc.edu.cn \
  -d \*.mirrors.ustc.edu.cn \
  --cert-file cert/mirrors/cert.pem \
  --key-file cert/mirrors/privkey.pem \
  --fullchain-file cert/mirrors/fullchain.pem
```

---

```shell
git -C cert add --all
git -C cert -c user.name=GitHub -c user.email=noreply@github.com commit \
    -m "Update certificates on $(date +%Y-%m-%d)" \
    -m "$(git log -1 --pretty='tformat:[%h] %an: %s' HEAD)"
git -C cert push
```

---

layout: true

## Vlab

---

![](https://vlab.ustc.edu.cn/docs/images/home.png)

---

layout: false
class: center, middle

<div><img src="https://vlab.ustc.edu.cn/docs/images/vlab-in-browser.jpg" /></div>

---

layout: true

## Vlab

---

- Xilinx Vivado
  - Multiple GBs of *slow* downloading
  - Hard to setup and maintain
- Other software (MATLAB, Wolfram Mathematica etc.)
  - Same size & complexity issues

--

<!-- -->
- <s>Another VPS provider</s>
- LXC containers
  - Lightweight
  - Host-manageable
  - System container (<s>application container</s>)

---

- Sharing & Isolation

--

<!-- -->
- Storage allocation: LVM
  - iSCSI isn't multi-mount-aware
  - ZFS doesn't support
  - NFS = SPOF

--
- But why does LVM work?

--
  - **"Activated volume"**
	- PVE native support: Only activate volumes in use by VMs/CTs

--

<!-- -->
- Network isolation: VXLAN
  - <span style="color: salmon;">❤</span> -50
  - Solution: Increase host <span style="color: salmon;">❤</span> to 1550

---

 User access:

- VNC unified login
  - 10,000 lines of C++ (by [pdlan](//github.com/pdlan))
	- Identify users via VNC login username
	  - Multi VM selection: `username:id`
	- Queries Django for VM information
- Browser login: noVNC

--
- SSH unified login
  - Modified from [tg123/sshpiper](//github.com/tg123/sshpiper)
  - Pubkey-based user identificaion
	- Certificate-based VM access
- Browser login: Wetty (alpha)

---

layout: false

<iframe
  src="https://vlab.ustc.edu.cn/grafana/d-solo/2/vlab-usage-statistics?orgId=1&from=1587065070291&to=1618601070291&theme=light&panelId=2"
  frameborder="0"
  style="width: 100%; height: 100%;"></iframe>

---

layout: true

## Miscellaneous

---

- Protect ports of VM from host (iptables)
  - SSH-based "authentication" ✔ 

---

```shell
:INPUT DROP [0:0]
# ...
:iBug - [0:0]
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j iBug
-A INPUT -g BLOCK

# ...
-A iBug -p icmp -j ACCEPT
-A iBug -p tcp -m multiport --dports 22,80,443,8888,25565 -j ACCEPT
-A iBug -m set ! --match-set home src -p tcp --dport 3389 -j BLOCK
```

`/etc/iptables/ipsets`:

```shell
create home hash:ip family inet timeout 600
```

---

`~/.ssh/rc`:

```shell
#!/bin/bash

if [ -z "$BASH" ]; then
  exec /bin/bash -- "$0" "$@"
  exit 1
fi

_ssh_client="${SSH_CONNECTION%% *}"
_ppid="$(ps -o ppid= $(ps -o ppid= $PPID))"

nohup /home/ubuntu/.local/bin/_ssh_refresh_client "$_ssh_client" "$_ppid" &>/dev/null & exit 0
```

---

`_ssh_refresh_client`:

```shell
#!/bin/bash

if [ -z "$BASH" ]; then
  exec /bin/bash -- "$0" "$@"
fi

_ssh_client="$1"
_ppid="$2"

while kill -0 "$_ppid" 2>/dev/null; do
  sudo ipset -exist add home "$_ssh_client" timeout 300
  sleep 60
done
exit 0
```

---

layout: false

## *Your* notification center

[iBug/rss-to-telegram](https://github.com/iBug/rss-to-telegram)

![](/image/rss-to-telegram.png)

---

## Cloudflare Worker makes free file sharing site

[iBug/cf-github-releases](https://github.com/iBug/cf-github-releases)

[My demo site](https://download.ibugone.com) ([Repository](https://github.com/iBug/Archive/releases))

![](/image/cloudflare/cf-github-releases.png)

---

class: center, middle
layout: false

# Thank you!
