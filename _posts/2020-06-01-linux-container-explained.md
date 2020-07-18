---
title: "A deep dive into Containers"
tags: linux container c
redirect_from: /p/23
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

## Namespaces

[Namespaces][linux-namespaces] are a fundamental aspect of Linux containers. They provide isolation for a variety of mission-critical system resources like process IDs, hostnames, network stacks and inter-process communication. They are the key to making containers "look independent" from the host system.

As of Linux kernel 5.6 released in April 2020, there are 8 kinds of namespaces present:

- **Mount namespace** isolates mount points (visibility) from the parent. New mount activities in the parent namespace won't be visible in child namespaces. However, to achieve the reverse, a separate thing called "mount propagation" is involved. First appeared in 2002, Linux 2.4.19.
- **UTS namespace** provides isolated hostnames. UTS stands for ["**U**NIX **T**ime-**S**haring system"][uts-system]. First appeared in 2006, Linux 2.6.19.
- **IPC namespace** isolates traditional System V-style IPC methods. First appeared in 2006, Linux 2.6.19.
- **PID namespace** provides a separate set of process IDs so that a process may look different inside. This is important for certain programs to function properly, most notably the init process, which must be PID 1. First appeared in 2008, Linux 2.6.24.
- **Networking namespace** provides a full set of network stack. Suitable for creating isolated network environments for containers. First appeared in 2009, Linux 2.6.29.
- **User namespace** allows mapping UIDs / GIDs from containers to hosts, so that unpriviledged users can perform certain tasks that normally require the superuser privilege, without actually elevating themselves or posing risks to the host. First appeared in 2013, Linux 3.8.
- **Cgroup namespace** provides isolated cgroup hierarchies so containers can safely utilize cgroup functionalities without affecting the host. First appeared in 2016, Linux 4.6.
- **Time namespace** allows different processes to "see" different system times. First appeared in 2020, Linux 5.6.

There are two ways to get namespaces isolated, [`unshare()`][unshare.2] and [`clone()`][clone.2]. A brief difference is that `unshare` isolates for the calling process (except PID namespace, check the manual for more details), while `clone` creates a new process with isolated namespaces. We'll go for `clone` because it's the system call underneath Go's `exec.Command`{:.language-go}, and that Go is used for popular container software like Docker and Singularity.

To utilize the `clone` system call, we need some adaptions, among which the most notable ones are the entry function and the child stack (using `mmap()`. I had problems later with `malloc()` in my early testing). The rest are covered pretty well by the manual so there's no need to repeat them here.

```c
int child(void *arg) {
    printf("My name is %s\n", (char *)arg);
    return 3;
}

int main() {
    char name[] = "child";

#define STACK_SIZE (1024 * 1024) // 1 MiB
    void *child_stack = mmap(NULL, STACK_SIZE,
                             PROT_READ | PROT_WRITE,
                             MAP_PRIVATE | MAP_ANONYMOUS | MAP_STACK,
                             -1, 0);
    // Assume stack grows downwards
    void *child_stack_start = child_stack + STACK_SIZE;

    int ch = clone(child, child_stack_start, SIGCHLD, name);
    int status;
    wait(&status);
    printf("Child exited with code %d\n", WEXITSTATUS(status));
    return 0;
}
```

And for the include headers as well.

```c
#define _GNU_SOURCE    // Required for enabling clone(2)
#include <stdio.h>
#include <sched.h>     // For clone(2)
#include <signal.h>    // For SIGCHLD constant
#include <sys/mman.h>  // For mmap(2)
#include <sys/types.h> // For wait(2)
#include <sys/wait.h>  // For wait(2)
```

Now that we have `clone` ready, adding support for namespace isolation is as simple as adding flags to the parameters.

```c
int ch = clone(child, child_stack_start, CLONE_NEWNS | CLONE_NEWUTS | CLONE_NEWIPC | CLONE_NEWPID | CLONE_NEWCGROUP | SIGCHLD, name);
```

## Mounts

Traditionally, mounting is a way to map raw disks to usable filesystems. Since then, its usage has evolved and supports much more than disk mapping. We're particularly interested in using special filesystems like `/proc` (the FS that provides runtime information like processes and kernel parameters), `/sys` (system settings, device information etc.), `/tmp` (a temporary filesystem backed by RAM) etc., without which a container won't function properly.

For a minimal example, we'll mount 4 "essential" filesystems with correct mount options for our container.

## References

- **Linux containers in 500 lines of code** by *Lizzie Dixon* - <https://blog.lizzie.io/linux-containers-in-500-loc.html>

  [linux-namespaces]: https://en.wikipedia.org/wiki/Linux_namespaces
  [uts-system]: https://en.wikipedia.org/wiki/History_of_Unix

  [unshare.2]: https://man7.org/linux/man-pages/man2/unshare.2.html
  [clone.2]: https://man7.org/linux/man-pages/man2/clone.2.html
