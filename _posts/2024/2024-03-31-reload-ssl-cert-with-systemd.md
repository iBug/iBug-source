---
title: Reload SSL certificates with systemd
tags: linux
redirect_from: /p/67
header:
  overlay_filter: 0.1
  overlay_image: /image/header/sunshine-1.jpg
---

Recently I relinquished an old domain on my server and had to re-issue a certificate to drop that domain off.
Previously it ran Let's Encrypt's official client Certbot, set up back in 2019.
All my recent setups have been using acme.sh, so I figured that this was a perfect chance to switch this one over as well.

Getting acme.sh to issue a new certificate for my updated domain list is easy enough and out of scope for this article.
But when it comes to reloading the certificate for services using it, I have to think twice.
Back in the days when Nginx was the sole consumer of the certificate, I directly referenced the certificate files in `/etc/letsencrypt/live/` from Nginx config, and somehow slappped a `systemctl reload nginx` into crontab to handle the reload.
Now that there are multiple services using the certificate, I no longer consider it a good idea to reload all the services in a crontab.
There has to be a better way.

Since all my services are managed by systemd, using an extra "service" or whatever unit to group them together seems like a better idea.
Systemd's `ReloadPropagatedFrom=` option and its inverse `PropagatesReloadTo=` immediately come to mind. With the right direction, it's easy to Google out this answer: [How do I reload a group of systemd services?](https://unix.stackexchange.com/q/334471/211239)

Realizing that "target" is the simplest unit type in systemd's abstraction, this is the minimum that suits my needs.

```ini
# /etc/systemd/system/ssl-certificate.target
[Unit]
Description=SSL certificates reload helper
PropagatesReloadTo=nginx.service
PropagatesReloadTo=postfix.service
```

Then, following the above Unix &amp; Linux answer, here's a "path" unit that lets systemd monitor the certificate files for changes.

```ini
# /etc/systemd/system/ssl-certificate.path
[Unit]
Description=SSL certificate reload helper
Wants=%N.target

[Path]
PathChanged=/etc/ssl/private/%H/cert.pem

[Install]
WantedBy=multi-user.target
```

The `Wants=` setting here ensure that the corresponding target unit is activated, otherwise it cannot be `reload`ed.

There's one deficiency in the answer above: A "path" unit can only *activate* another unit, not *reload* it. So I still have to create a oneshot service that calls `systemctl reload` on the target, which itself can then be activated by the "path" unit.

```ini
# /etc/systemd/system/ssl-certificate.service
[Unit]
Description=SSL certificate reload helper
StartLimitIntervalSec=5s
StartLimitBurst=2

[Service]
Type=oneshot
ExecStart=/bin/systemctl reload %N.target
```

It's important that this service comes with `Type=oneshot` and *without* `RemainAfterExit=yes`, so that it can be repeatedly activated by the "path" unit.

Now I can test if things work:

```shell
systemctl daemon-reload
systemctl enable --now ssl-certificate.path
acme.sh --install-cert -d "$HOSTNAME" \
  --cert-file "/etc/ssl/private/$HOSTNAME/cert.pem" \
  --key-file "/etc/ssl/private/$HOSTNAME/privkey.pem" \
  --fullchain-file "/etc/ssl/private/$HOSTNAME/fullchain.pem"
```

And then inspect the services:

```console
$ systemctl status nginx.service
[...]
Mar 31 19:20:11 hostname systemd[1]: Reloading A high performance web server and a reverse proxy server...
Mar 31 19:20:12 hostname systemd[1]: Reloaded A high performance web server and a reverse proxy server.

$ systemctl status postfix.service
[...]
Mar 31 19:20:11 hostname systemd[1]: Reloading Postfix Mail Transport Agent...
Mar 31 19:20:12 hostname systemd[1]: Reloaded Postfix Mail Transport Agent.
```

So now, job done. As acme.sh stores install information, the next time these certificates are renewed, acme.sh will automatically copy them over to `/etc/ssl/private/$HOSTNAME/`, and systemd will pick up the changes and reload the services.

  [1-unused]: https://seb.jambor.dev/posts/systemd-by-example-part-1-minimization/
