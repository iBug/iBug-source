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

## Signing host keys

## Signing user keys

## Configuring servers to trust the CA

## Configuring clients to trust the CA

## Epilogue


  [ca]: https://en.wikipedia.org/wiki/Certificate_authority
  [termux]: https://termux.com/
