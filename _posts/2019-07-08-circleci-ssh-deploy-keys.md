---
title: Using SSH deploy keys on CircleCI
tags: development github-pages
redirect_from:
  - /p/21
  - /blog/2019/07/circleci-ssh-delpoy-keys/
---

A year ago back I [wrote an article][1] on automating build & deployment of GitHub Pages website with Travis CI. It's a great CI service at first, but since [Travis CI has completely moved away from containers][2], speed is a real issue to whoever is concerned. On the other side, CircleCI is continuing their builds with Docker-based containers, whose rapid response is a *great* advantage against VMs with slow boot time.

Migrating the build script from Travis CI was an intuitive and easy step, but I immediately got disappointed by CircleCI's logging: Secret environment variables get exposed in the log as soon as any command or program prints them.

![image](/image/circleci/token-leak.png)

That's particularly annoying because I used Personal Access Tokens to push built content back to GitHub, and this kind of straightforward leaks is a huge security issue, so I looked around for alternatives, and came up with the idea of using a deploy key with write access.

Setting up the basics wasn't any difficult on its own for anyone with a bit experience in Linux:

- Generate an SSH key pair with `ssh-keygen`
- Encode (or compress + encode) the private key and put it into the CI environment
- Create a build script to grab key from environment and utilize it

Once you've figured out the build script, everything appears straightforward:

```shell
if [ -z "$SSH_KEY_E" ]; then
  e_error "No SSH key found in environment."
  exit 1
fi

base64 -d <<< "$SSH_KEY_E" | gunzip -c > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
git clone --depth=3 --branch=$BRANCH "git@github.com:$GH_REPO.git" _site
```

At first glance, it *should* work without any problem. But that's apparently only an *assumption*, no? And if you follow the build log, you'll immediately know when it runs into *the problem*:

```text
ERROR: The key you are authenticating with has been marked as read only.
```

It's particularly confusing when you've written your SSH private key to the correct path, set the correct permission and expecting SSH to respect your key, only to find it's actually offering another key to GitHub and fails.

![image](/image/circleci/ssh-fail.png)

Digging around with debug information (set `GIT_SSH_COMMAND='ssh -vv'`), I noticed this absurd thing:

![image](/image/circleci/key-not-found.png)

Clearly, the aptly placed key wasn't even found by SSH, rendering it completely unusable in status quo. I've even tried crafting `~/.ssh/config`, but unfortunately it's ignored as well.

### Solution

Just like most other CLI utilities, SSH respects command-line arguments loyally. So you would just specify the identity file there:

```shell
export GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa'
```

![image](/image/circleci/solution.png)

And I don't even know what's going on behind the scenes, but it just works.

Reference: [Stack Overflow](https://stackoverflow.com/q/55177042/5958455)

[1]: /p/4
[2]:https://blog.travis-ci.com/2018-10-04-combining-linux-infrastructures
