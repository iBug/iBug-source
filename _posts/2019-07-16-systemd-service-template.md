---
title: 'Creating templated Systemd services'
tags: linux
redirect_from: /p/22
---

Last time I wrote an article about [NAT traversal using FRP][1], which has been my personal solution for exposing SSH access of machines behind NAT to the internet for a long time.

As time goes by, I get more devices behind NAT and more VPS hosts providing FRP access, and the need for connecting one device with multiple FRP hosts arises. Surely, one solution would be writing multiple config files and Systemd service files for each instance of `frpc`, which would just run perfectly.

## Writing multiple Systemd service files

Let's start this with one `frpc.service` file that I wrote and am using:

```ini
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

Now I want to add another `frpc` instance with an alternate configuration, I could just copy the above file, modify the `ExecStart` line, and save it as another file.

However, that's undoubtably a suboptimal solution, especially given that Systemd service files can use "template variables"[^1]. Having too many *otherwise* identical service configuration files is particularly prone to making a mess. With "template variables", you can simplify all this job into one single file

## Using Systemd service instance variables

Among all "instance variables", the most commonly used one is "instance name" `%i`. You'll just replace the variable part with `%i`, and in my case, it's the config file name for `frpc`.

Instead of putting `frpc` config files directly under `/etc`, the first thing I did is making a directory `/etc/frpc` for all of them. Then I put the "default" one into the directory as `/etc/frpc/default.ini`, and re-written the service file, utilizing instance variables, as this:

```ini
[Unit]
Description=FRP Client Service (%i)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/local/bin/frpc -c /etc/%i.ini

[Install]
WantedBy=multi-user.target
```

Notice the two appearances of `%i` here: The first one in unit description, and the second one on the line `ExecStart`.

There's also another thing to note: It's no longer applicable to name the file as `frpc.service`, but instead, `frpc@.service`. The AT sign in the file name indicates it's a "template service".

Now, to instantiate the `frpc@` service into instance "default" (which is also the config file name in `/etc/frpc`), the following commands were used to manage it:

```shell
systemctl start frpc@default.service
systemctl stop frpc@default.service
systemctl enable frpc@default.service
```

And an extra note on the `enable` command: If you notice the output from `systemctl`, it should read like this:

```console
ibug@ubuntu:~$ sudo systemctl enable frpc@example.service
Created symlink /etc/systemd/system/multi-user.target.wants/frpc@example.service → /etc/systemd/system/frpc@.service
```

Yep, the file isn't modified in any way, only a symlink is created.

As you can guess, the instance name `%i` is substituted at the time the file is parsed. This means you can modify the service file on the go and any changes will take effect the next time you run a `systemctl` command that reads the file.

And here's the topic: For each additional `frpc` instance, the only thing to do is to place its config file under `/etc/frpc/something.ini`, and the new instance can be launched at `frpc@something`.

For a complete list of instance specifiers, [here][2]'s a good reference. Time to get yourself some work to cleanup your messy Systemd services :)

[^1]: It's official name is "instance specifier", which IMO is less intuitive.

[1]: /p/14
[2]: https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers
