---
title: "Managing my servers with OpenSSH Certificate Authority"
tags: linux ssh
redirect_from: /p/30

published: false
---

Since the addition of the website server for an external corporation, I now have 5 Linux servers to manage on my own. I also have 4 terminal devices that I use to connect to those servers: two of my laptops, my Android phone (using [Termux][termux]), and one of those servers that I use as a workstation.

Managing SSH keys has always been a headache for this many computers, as all of them on one side have to be updated of the new key whenever one on the other side changes or rotates its key. In case of a client key change, the new key must be uploaded to all servers. And in a worse case where the original key is lost, the uploading needs to be done with the help of another client (computer or phone), which is an additional layer of unnecessary complexity and cumber.

Not until I took over a system of many servers did I learn about SSH CA. It's for sure to the rescue!

## What is an SSH CA?

Long story short, an SSH Certificate Authority is a [certificate authority][ca] for SSH hosts. A client can trust all server signed by the CA by simply trusting the CA. And more powerfully, a server can *also* trust all user keys if the user key has a signature from the CA, and the server trusts the CA for signing user keys.

By properly configuring servers and clients, a rotated or otherwise changed key, be it a host key or a user key, will no longer cause chaos of copying public keys from everywhere, to everyone. The follow-up is as simple as getting another CA signature for the new key, and everything will go smoothly as if nothing has happened.

## Creating an SSH CA

Creating a CA is as easy as generating a key pair for it, and publishing its public key.

To generate a key pair for a CA, you'd do it the usual way you generate a regular SSH key pair:

```shell
ssh-keygen -f my_ca
```

Proceed through the prompts, and you'll find two files `my_ca` and `my_ca.pub` in your current directory. Contrary to SSH keys that you use for regular purposes, I highly recommend setting a password for this key, since it's going to be *way* more powerful than those. Protect the private key carefully, and leave the public part somewhere easily accessible, like [mine](https://ibugone.com/assets/ssh-ca.pub.txt).

## Authenticating hosts with SSH CA

### Sign a host key

To sign a host key with your CA, copy its **public** part (like `ssh_host_rsa_key.pub`) to a convenient place, and run the following command.

```shell
ssh-keygen -s <ca private key> -I <signature name> -h <host key>
```

You'll find a file named `ssh_host_rsa_key-cert.pub` in your current directory, which you should copy back to the server. Because sshd(8) doesn't look for host certificates by default, you shold edit `/etc/ssh/sshd_config` to instruct it to do so. Add this line to the file to let it work:

```text
HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
```

Then run `systemctl reload ssh` (or `service sshd reload` if you're not running on systemd) to reload the configuration.

### Restrict signature validity range

As a security measure, you probably don't want the signature remain valid even if stolen. The `-n` option is there for you to specify "valid principals". For example, you can specify a signature valid for `s.ibugone.com,10.250.0.2`, and this signature is accepted by clients only if the server is accessed from `s.ibugone.com` or `10.250.0.2`. If someone steals the private key and the CA signature and installs it on another host, for example `q.ibugone.com` or `10.250.0.3`, the SSH client will complain:

```text
Certificate invalid: name is not a listed principal
```

Unless the attacker can hijack your DNS (for authenticated domain names) or even your routers (for plain IP addresses), this signature is useless when stolen, and you can safely forget about it and sign a new one for the regenerated host key.

You can see the certificate information using `ssh-keygen -L` command. For example:

```shell
ssh-keygen -Lf /etc/ssh/ssh_host_rsa_key-cert.pub
```

### Configure clients

Now let's configure clients to trust CA signatures. You'll need to publish the public key of the CA (as said before) so clients can easily acquire it. Put a line like this in a client's `known_hosts` file:

```text
@cert-authority * ssh-rsa <publicKeyGibberish>
```

You can automate the addition of the above line using shell scripts:

```shell
printf "@cert-authority * " | cat - my_ca.pub >> ~/.ssh/known_hosts
```

Now try SSHing into a host with a CA signature. You'll notice that SSH doesn't prompt for "unknown host" even if it's not listed in the `known_hosts` file, which is because of the magic of the `@cert-authority` line. Should you be interested in the details, you can use `ssh -vvv` to let SSH client generate extra information.

## Authenticating users with SSH CA

## Epilogue


  [ca]: https://en.wikipedia.org/wiki/Certificate_authority
  [termux]: https://termux.com/
