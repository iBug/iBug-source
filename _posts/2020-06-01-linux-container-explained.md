---
title: "A deep dive into Containers"
tags: linux container c
redirect_from: /p/36
header:
  actions:
    - label: "<i class='fab fa-github'></i> GitHub"
      url: https://github.com/iBug/iSpawn
    - label: "<i class='fas fa-file-alt'></i> 实验文档"
      url: https://osh-2020.github.io/lab-4/

published: false
---

Since years ago containers have been a hot topic everywhere. There are many container softwares like [Docker][docker], [Linux Containers][lxc] and [Singularity][singularity]. It's hard to say one *understand* what containers are without diving into all the gory details of them, so I decided to go on this exploration myself.

  [docker]: https://www.docker.com/
  [lxc]: https://linuxcontainers.org/
  [singularity]: https://sylabs.io/singularity/

The actual motivation was (quite) a bit different, though, as I am the TA of *Operating Systems (H)* this semester, and I want to inject a spirit of innovation into the course labs, so I worked this out very early.

The contents in this article are listed in the Table of Contents on the right (if you're on a computer) or at the top of this page (if you're on a mobile). The GitHub repository containing my implementation and the original lab documents (which is also written primarily by me, in Chinese) are referred to right under the title.

My test environment is Ubuntu 20.04 LTS (Kernel 5.4). In case of any differences, you can search Google for details.

## Experimenting with isolation

### Preparing the root filesystem

To keep things simple, we're going to use the system images from the LXC project. Grab the latest Ubuntu image from <https://images.linuxcontainers.org/images/ubuntu/>, unzip it to somewhere convenient for you, and this part is *almost* done.

If you're on a "modern" distro like latest Ubuntu, Debian or Fedora, you need to populate the `/etc/machine-id` file in the container image with a valid "machine ID", because systemd needs it. A simple way to do this is

```shell
systemd-machine-id-setup --root=/path/to/your/rootfs
```

If you're running systemd 240 or later, there's a better neat tool for this job:

```shell
systemd-id128 new > /path/to/your/rootfs/etc/machine-id
```

### Playing with chroot

[chroot][chroot] is an old way to limit the directory tree a process (and its subprocesses) can see to a specific subtree. Under normal circumstances, processes cannot see anything outsite the chroot'd directory. This is called a *chroot jail*. Understanding the concepts of chroot is an important first step to understanding containers, though a typical container does *not* use chroot (more on this below).

Using chroot is very easy:

```shell
chroot /path/to/your/rootfs
```

You now get a shell inside the *chroot jail*. You can perform file-based operation like running "regular" commands and editing system files. All changes are saved in this "container rootfs". You can even try `apt update` and `apt install vim` and see if it works.

As you're probably aware, chroot is just too simple and sometimes naive to be secure. You can try the following commands, but be sure to save your work. **Proceed with caution!**

```shell
reboot
mount
dd if=/dev/sda of=test bs=4k count=1
echo $$
```

  [chroot]: https://wiki.debian.org/chroot

### Playing with systemd-nspawn

As you can see, chroot lacks too many security constaints. [Systemd-nspawn][nspawn], on the other hand, is a *complete* container implementation and is thus secure against random programs.

Using systemd-nspawn is equally easy:

```shell
cd /path/to/your/rootfs
systemd-nspawn
```

Now repeat your experiments in the chroot section and carefully observe the differences.

  [nspawn]: https://wiki.debian.org/nspawn

## The base program

After getting your rootfs up for rocking, we'll start with a fairly simple chroot-based program, modify it step-by-step, until it becomes the container we want.

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h> // For wait(2)
#include <sys/wait.h>  // For wait(2)

const char *usage =
"Usage: %s <directory> <command> [args...]\n"
"\n"
"  Run <directory> as a container and execute <command>.\n";

void error_exit(int code, const char *message) {
    perror(message);
    _exit(code);
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, usage, argv[0]);
        return 1;
    }
    if (chdir(argv[1]) == -1)
        error_exit(1, argv[1]);

    pid_t pid = fork();
    if (pid == 0) {
        // Child goes for target program
        if (chroot(".") == -1)
            error_exit(1, "chroot");
        execvp(argv[2], argv + 2);
        error_exit(255, "exec");
    }

    // Parent waits for child
    int status, ecode = 0;
    wait(&status);
    if (WIFEXITED(status)) {
        printf("Exited with status %d\n", WEXITSTATUS(status));
        ecode = WEXITSTATUS(status);
    } else if (WIFSIGNALED(status)) {
        printf("Killed by signal %d\n", WTERMSIG(status));
        ecode = -WTERMSIG(status);
    }
    return ecode;
}
```

## Mounts
