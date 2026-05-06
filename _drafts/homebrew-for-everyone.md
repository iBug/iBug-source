---
title: "Homebrew for Everyone: Easy FUSE trick for multi-user Homebrew on Linux setup"
tags: linux
redirect_from: /p/80
---

If you have tried looking for a multi-user Homebrew setup, chances are, [this article][codejam] from CodeJam is among your top Google results and you have read it many a time.
It shared experiences of using a shared Homebrew setup and discussed three ways to make it work.
Namely,

1. Adding group-writable permission (`g+w`) on the Homebrew installation directory and add everyone to the homebrew group.

   This worked at first until `brew` itself introduced more files without group-writable modes due to the default umask setup (presumably `0022`).

2. Have every user install their own Homebrew, with extra installations going to non-default prefix locations.

   This worked reliably, with a major downside being having to compile *everything* from scratch, due to Homebrew casks relying on hardcoded default prefix (e.g. `/opt/homebrew` on macOS and `/home/linuxbrew/.linuxbrew` on Linux).
   In particular, on Linux, the dynamic linker path embedded in ELF binaries is `/home/linuxbrew/.linuxbrew/lib/ld.so`.
   Guess that's why you have to compile everything from scratch.
   It's neither productive nor energy-efficient.

3. Create a shared user for Homebrew and have everyone `sudo` into it.

  [codejam]: https://www.codejam.info/2021/11/homebrew-multi-user.html 

The last option is indeed the best, and with shell aliasing to automatically prepend `brew` commands with `sudo`, usage experience is as smooth as regular single-user setup.

There is one implication, however, that every `brew` user must trust each other for not installing a malicious `ls` command.

This is the case for CodeJam, as both system users are the same physical user.
However, it may not always be the case, like on lab servers or shared workstations.

Is there a better way to allow every users install and manage their own Homebrew separately?

## The idea {#idea}

To make things easier, I'll focus on Homebew on Linux as I work exclusively with Linux.

Since there's only one default prefix at `/home/linuxbrew/.linuxbrew` and its content is all stored with owner and group being the user who installed it, what if Homebrew can be installed in the user's home directory and visible from the default prefix?

The first thing that came to my mind is `CLONE_NEWNS`, so that I can bind-mount the actual installation onto Homebrew's prefix in each user's own namespace.
To make things usable, this has to be implemented through systemd-logind so the mount namespace is applied on user login, possibly onto user service manager (i.e. `user@.service`).

## The solution {#solution}
