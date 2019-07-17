---
title: 'Creating Templated Systemd Services'
tags: linux
redirect_from: /p/22

published: false
---

Last time I wrote an article about [NAT traversal using FRP][1], which has been my personal solution for exposing SSH access of machines behind NAT to the internet for a long time.

As time goes by, I get more devices behind NAT and more VPS hosts providing FRP access, and the need for connecting one device with multiple FRP hosts arises. Surely, one solution would be writing multiple config files and Systemd service files for each instance of `frpc`, which would just run perfectly.

## Writing multiple Systemd service files

Let's start this with one `frpc.service` file that I wrote and am using:

```text
[Unit]
Description=FRP Client Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/local/bin/frpc -c /etc/frpc.ini

[Install]
WantedBy=multi-user.target
```

Now I want to add another `frpc` instance with an alternate configuration, I could just copy the above file, modify the `ExecStart` line, and save it as another file

However, that's undoubtably a suboptimal solution, especially given that Systemd service files can use "template variables"[^1].

[^1]: It's official name is "instance variables", which IMO is less intuitive in some cases or to some people.

[1]: /p/14
[2]: https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers