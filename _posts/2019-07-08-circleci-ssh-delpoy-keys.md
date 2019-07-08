---
title: Using SSH deploy keys on CircleCI
tags: development github-pages
redirect_from: /p/21

published: false
---

A year ago back I [wrote an article][1] on automating build & deployment of GitHub Pages website with Travis CI. It's a great CI service at first, but since [Travis CI has completely moved away from containers][2], speed is a real issue to whoever is concerned. On the other side, CircleCI is continuing their builds with Docker-based containers, whose rapid response is a *great* advantage against VMs with slow boot time.

Migrating the build script from Travis CI was an intuitive and easy step, but I immediately got disappointed by CircleCI's logging: Secret environment variables get exposed in the log as long as any command or program prints them.

![image](/image/circleci-token-leak.png)

That's particularly annoying because I used Personal Access Tokens to push built content back to GitHub, and this kind of straightforward leaks is a huge security issue, so I looked around for alternatives, and came up with the idea of using a deploy key with write access.

Setting up the basics wasn't any difficult on its own for anyone with a bit experience in Linux:

- Generate an SSH key pair with `ssh-keygen`
- Encode (or compress + encode) the private key and put it into the CI environment



[1]: /p/4
[2]:https://blog.travis-ci.com/2018-10-04-combining-linux-infrastructures