---
title: "Access your Raspberry Pi remotely with SSH"
description: null
tagline: "Remote control is fun"
tags: linux networking
redirect_from: /p/14

show_view: false
view_name: "Stack Overflow"
view_url: "https://stackoverflow.com"
show_download: false
download_name: "Stack Overflow"
download_url: "https://stackoverflow.com"

published: true
---

Do you have a personal server at home but can't access it from work or travel because your home doesn't have a public IP? If so, then, this article is what you're looking for.

In my case, I have a Raspberry Pi at my home, and I need some remote SSH from outside. And here's how I made it work.

# Prerequisites

The server hardware, and a VPS with a public IP (for forwarding)

# Server setup

The software I use is [frp][1] (**f**ast **r**everse **p**roxy). It's written in Go and is designed specifically for port forwarding.

To setup the server, grab a release. I use 0.17.0 but you can always prefer the latest release.

```shell
cd
wget https://github.com/fatedier/frp/releases/download/v0.17.0/frp_0.17.0_linux_amd64.tar.gz
tar zxvf frp_0.17.0_linux_amd64.tar.gz
mv frp_0.17.0_linux_amd64 frp
cd frp
```

Now open the configuration file `frps.ini` with your favorite editor, Vim or Emacs, and put the following content in:

```text
[common]
bind_port = 7000
privilege_token = your_token

dashboard_port = 8080
dashboard_user = admin
dashboard_pwd = password
```

In fact, you only need the top two configuration items, `bind_port` and `privilege_token`. There's a `frps_full.ini` in the package if you want to dig deeper, but I'll keep things simple here.

- `bind_port`: The port for `frps` (FRP Server) to listen for clients.
- `privilege_token`: A token for clients to authenticate. Think it as the password of your Wi-Fi AP.

The following three items together provide a web dashboard for you to monitor status. They're completely optional and you can leave them out if you don't need the dashboard, or set it to whatever value you find convenient for you. Their names should be self-explanatory.

Now, start the server:

```shell
./frps -c ./frps.ini
```

If you see logs in your terminal output, then you're good to go!

In most cases, it'd be convenient for the server software to start as a daemon, and automatically start at boot. The way I chose is creating a systemd system service, so it's possible to use commands like `service frps start` to manage it.

Create the file `/etc/systemd/system/frps.service` with the following content:

```text
[Unit]
Description=FRP Server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=ubuntu
ExecStart=/home/ubuntu/frp/frps -c /home/ubuntu/frp/frps.ini

[Install]
WantedBy=multi-user.target
```

Take note of Line 10 and Line 11. You need to set the user to your username and change the paths as your setup goes.

After creating the service registry file, you can start the FRP server with `service frps start` and check its status with `service frps status`.

For insurance, I added `service frps start` to `/etc/rc.local` so it will start at boot.

Now the server side is fully set up and ready to use.

# Client setup

Setting up the client machine is pretty much symmetric to setting up the server and the procedure isn't much different.

My client machine is a $35 Raspberry Pi running Raspbian, so I picked the ARM version of prebuilt binary.

```shell
cd
wget https://github.com/fatedier/frp/releases/download/v0.17.0/frp_0.17.0_linux_arm.tar.gz
tar zxvf frp_0.17.0_linux_arm.tar.gz
mv frp_0.17.0_linux_arm frp
cd frp
```

This time, open `frpc.ini` with your favorite editor, and put the following content in:

```text
[common]
server_addr = <your server ip>
server_port = 7000
privilege_token = your_token
login_fail_exit = true

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 8022
```

Put the IP address of your server in `server_addr`, and your privilege token in the configuration file, then it's set. You may need to change `remote_port` to another value if 8022 is occupied by another program on your server.

Similar to the server software, I created another systemd service for the client software. Here's what I have in my `/etc/systemd/system/frpc.service`:

```text
[Unit]
Description=FRP Client
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=pi
ExecStart=/home/pi/frp/frpc -c /home/pi/frp/frpc.ini

[Install]
WantedBy=multi-user.target
```

That's pretty much identical to the server service, no?

The last thing is to put `service frpc start` in an appropriate place in `/etc/rc.local` so the FRP client starts at boot.

Now that both sides are set, let's try it out.

# Running SSH remotely

You can SSH into your Raspberry Pi as usual, just remember to change the host name to your VPS, and specify the port as set during client setup.

```shell
ssh pi@<your server ip> -p 8022
```

See the shell popping up from your RPi? Congratulations! You're good to go.

For convenience, you can add the remote SSH configuration to your local SSH config file `~/.ssh/config`, so you can access with ease in the future.

```text
Host pi-remote
  HostName <your server ip>
  Port 8022
  User pi
  PubKeyAuthentication yes
  PasswordAuthentication yes
  IdentityFile ~/.ssh/id_rsa
```

And then, you can SSH into your Raspberry Pi remotely with `ssh pi-remote`, and let SSH handle the rest.


  [1]: https://github.com/fatedier/frp
