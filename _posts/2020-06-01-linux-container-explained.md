---
title: "A Deep Dive into Containers"
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

Since years ago, containers have been a hot topic everywhere. There are many container softwares like [Docker][docker], [Linux Containers][lxc] and [Singularity][singularity]. It's hard to say one *understand* what containers are without diving into all the gory details of them, so I decided to go on this exploration myself.

  [docker]: https://www.docker.com/
  [lxc]: https://linuxcontainers.org/
  [singularity]: https://sylabs.io/singularity/

The actual motivation was (quite) a bit different, though, as I am the TA of *Operating Systems (H)* this semester, and I want to inject a spirit of innovation into the course labs, so I worked this out very early.

The contents in this article are listed in the Table of Contents on the right (if you're on a computer) or at the top of this page (if you're on a mobile). The GitHub repository containing my implementation and the original lab documents (which is also written primarily by me, in Chinese) are linked under the title.

My test environment is Ubuntu 18.04 LTS (Kernel 5.3) and 20.04 LTS (Kernel 5.4). In case of any difference, you can consult Google for details.

In case you want to find out the exact system calls involved in a command-line tool, [`strace`][strace] is your friend.

  [strace]: https://strace.io/

## Experimenting with isolation {#experimenting}

### Preparing the root filesystem {#rootfs}

To keep things simple, we're going to use the system images from the LXC project. Grab the latest Ubuntu image from <https://images.linuxcontainers.org/images/ubuntu/>, unzip it to somewhere convenient for you, and this part is *almost* done.

If you're on a "modern" distro like latest Ubuntu, Debian or Fedora, you need to populate the `/etc/machine-id` file in the container image with a valid "machine ID", because systemd needs it. A simple way to do this is

```shell
systemd-machine-id-setup --root=/path/to/your/rootfs
```

If you're running systemd 240 or later, there's a better neat tool for this job:

```shell
systemd-id128 new > /path/to/your/rootfs/etc/machine-id
```

### Playing with chroot {#chroot}

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

### Playing with systemd-nspawn {#systemd-nspawn}

As you can see, chroot lacks too many security constaints. [Systemd-nspawn][nspawn], on the other hand, is a *complete* container implementation and is thus secure against random programs.

Using systemd-nspawn is equally easy:

```shell
cd /path/to/your/rootfs
systemd-nspawn
```

Now repeat your experiments in the chroot section and carefully observe the differences.

  [nspawn]: https://wiki.debian.org/nspawn

## The base program {#base-program}

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

To utilize the `clone` system call, we need some adaptions, among which the most notable ones are the entry function and the child stack (using `mmap()`, I had problems later with `malloc()` in my early testing). The rest are covered pretty well in the manual so there's no need to repeat them here (e.g. `SIGCHLD` appearing in `flags` parameter).

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

Traditionally, mounting is a way to map raw disks to accessible filesystems. Since then, its usage has evolved and supports much more than disk mapping. We're particularly interested in using special filesystems like `/proc` (the FS that provides runtime information like processes and kernel parameters), `/sys` (system settings, device information etc.), `/tmp` (a temporary filesystem backed by RAM) etc., without which a container won't function properly.

For a minimal example, we'll mount 4 essential filesystems with correct mount options for our container. They are the three mentioned above plus `/dev` as a tmpfs. We'll also create a few device nodes under `/dev` so things can go smoothly when they're needed (e.g. `some_command > /dev/null`).

<div class="notice--primary" markdown="1">
#### <i class="fas fa-times-circle"></i> We're not using `devtmpfs` here
{: .no_toc }

If you examine current mounts in your host system, you'll probably see that `/dev` is mounted as `devtmpfs`. While it may appear straightforward to employ that, it's unacceptable for **a container**, as it exposes *all* device nodes to the container, which violates the purpose of isolation of containers. See [this answer](https://unix.stackexchange.com/q/77933/211239) on Unix & Linux Stack Exchange.
</div>

To do this manually, you'll issue the following commands in a shell.

```shell
mount -t tmpfs tmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs tmpfs /tmp
```

Now we're going to do it in C. The system call is also named `mount`, and has the following signature:

```c
int mount(const char *source, const char *target,
          const char *filesystemtype, unsigned long mountflags,
          const void *data);
```

It should be intuitive enough what the first three parameters are for, so for now we can just write

```c
mount("tmpfs", "/dev", "tmpfs", 0, NULL);
mount("proc", "/proc", "proc", 0, NULL);
mount("sysfs", "/sys", "sysfs", 0, NULL);
mount("tmpfs", "/tmp", "tmpfs", 0, NULL);
```

But keep in mind, it in no way implies that the last two parameters are useless. They're simply not used for now, but for sure they'll play a role later.

## pivot\_root

We're ready with mounts, so now we can take a look at switching the root filesystem for our container.

The [base program](#base-program) used `chroot()` for the time being, but talking about a (baseline) secure container, [it's terrible][chw00t]. We have to resort to another Linux feature, `pivot_root`, for this purpose.

Let's first take a look at [its man page][pivot_root.2] to determine its prototype.

```c
int pivot_root(const char *new_root, const char *put_old);
```

This system call is special enough that we must also take care of its notes and requirements. For example, `new_root` must be a mount point. While the man page does provide a solution to this problem by mounting the directory on top of itself, it's too prone to errors for us to adopt. Instead we'll be creating a temporary directory to use as the mount point.

```c
const char *newroot = "/tmp/ispawn";
mkdir(newroot, 0755);
```

We also need a value for the second parameter to `pivot_root`, the `put_old` directory. The manual says the following:

> `put_old` must be at or underneath `new_root`

A direct interpretation is that `put_old` must be at a subpath under `new_root`, which means we can simply create (or reuse an existing) a directory under `new_root` to use.

```c
const char *put_old = "/tmp/ispawn/oldroot";
mkdir(put_old);
```

And now we can do `pivot_root` with the directories we just set up:

```c
pivot_root(newroot, put_old);
```

If everything so far is correct, we should now be running inside the new root tree. The "old root", or the root filesystem of the host system, is now available at `/oldroot`.

Apparently, a container shouldn't be able to access the host filesystem without explicit grants, so we're going to "hide" the old root. It is, from the view from within the container, an ordinary mount point that we can just unmount. However, as there (definitely) are other processes in the host system still using the filesystem, it can't be unmounted directly.

There's a technique called "lazy unmounting", where existing processes continue to use the filesystem as usual, while other processes see it disappeared. It [could be dangerous][lazy-umount], but as we're the one-and-only process inside the container, we know it's safe for us.

With that many information told, the actual code is really simple:

```c
umount2("/oldroot", MNT_DETACH);
```

We're using the `umount2` system call because we need to pass the extra flags to it. Now that the host filesystem is gone, we can remove the now-empty directory (remember we're doing clean-up jobs):

```c
rmdir("/oldroot");
```

We've isolated our container filesystem from the host system, and then we can proceed to securing and fortifying our container.


## Capabilities

In the traditional UNIX era, there were only two privilege levels - *privileged* (root) and *unprivileged* (non-root), where a *privileged* process has every privilege to alter the system, while an *unprivileged* process has none. Since Linux 2.2 in 1999, *capabilities* have been added to the kernel so that unprivileged processes may acquire certain abilities needed for some task, while privileged processes may drop capabilities unneeded, allowing for privilege control at a finer granularity. A `ping` process doesn't need any extra privileges than sending ICMP packets, and a web server (probably) doesn't need any extra privileges than binding to a low port (1 to 1023), do they?

With capabilities, unprivileged processes can be granted access to selected system functionalities, while privileged processes can be deprived of selected ones. For example, `CAP_NET_BIND_SERVICE` is the capability to bind to TCP or UDP ports between 1 and 1023, and `CAP_CHOWN` enables the use of `chown(2)`.

Now turning our focus back to containers. Without privilege separation, a "root" process inside a container can still do dangerous things, like scanning your hard drive where the host filesystem resides, and manipulate it. This is definitely not anything expected, so we're going to limit the capabilities the container can have as a whole.

The system calls behind capabilities manipulation are very complicated, so unlike in previous sections, we're going to use wrapped-up libraries to aid with this. There are two options available, `libcap` and `libcap-ng`, of which the latter is easier to understand and use. The documentations for [libcap][libcap-docs] and [libcap-ng][libcap-ng-docs] are given. Note that since they're "external" libraries, extra flags need to be supplied when compiling. For libcap you'll add `-lcap` to the compilation command, and similarly for libcap-ng you'll add `-lcap-ng` to the command.

As an easier starting point, we'll use [Docker's capabilities set][docker-caps] to avoid having to sort everything out by ourselves. Before we start, there's another thing to learn - the different "sets" of capabilities of a process. In a few short words,

- The *bounding* set restricts the maximum possible set of capabilities a process (and all its descendants) can have
- The *effective* set is what a process currently has and is effective
- The *permitted* set may be granted when "asked" (using the appropriate system calls)

It's noticeable that we want to limit all three sets for the container. Using libcap-ng, the code is very simple:

```c
capng_clear(CAPNG_SELECT_BOTH);
capng_updatev(CAPNG_ADD, (capng_type_t)(CAPNG_EFFECTIVE | CAPNG_PERMITTED | CAPNG_BOUNDING_SET),
    CAP_SETPCAP,
    // ...
    CAP_SETFCAP,
    -1);
capng_apply(CAPNG_SELECT_BOTH);
```

With `capng_clear`, we clear all capabilities from our pending changes, and add whitelisted capabilities, before finally applying the changes.

Using libcap, however, is slightly more complicated to achieve the same, as there's no direct "clear all" function, but instead you'll have to list them by yourself. [Here][cap-switch-lib]'s an older version of my attempted code if you want to learn. Nevertheless, it's never bad to learn more.

  [libcap-docs]: https://linux.die.net/man/3/libcap
  [libcap-ng-docs]: https://people.redhat.com/sgrubb/libcap-ng/
  [docker-caps]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
  [cap-switch-lib]: https://github.com/iBug/iSpawn/commit/bcf27bf42771e7fd8c7f24abbec5907f6f727fd7


## SecComp

SecComp (Secure Computing) is a security module in Linux that lets a process to transition one-way into a "secure state" where no system call other than `read()`, `write()`, `sigreturn()` and `exit()` is allowed. It's easily noticeable that this feature is too strict for making something useful, and **seccomp-bpf** is an extension to the rescue.

Seccomp BPF extends the seccomp module with Berkeley Packer Filter (BPF), an embedded instruction set that allows highly customized seccomp rules to be deployed. With BPF, you can create custom logic for system call filtering, including matching and testing individual system call arguments. 

## Resource restriction

## Conclusion

### Other reading

- **Linux containers in 500 lines of code** by *Lizzie Dixon* - <https://blog.lizzie.io/linux-containers-in-500-loc.html>


  [linux-namespaces]: https://en.wikipedia.org/wiki/Linux_namespaces
  [uts-system]: https://en.wikipedia.org/wiki/History_of_Unix
  [chw00t]: https://github.com/earthquake/chw00t
  [lazy-umount]: https://unix.stackexchange.com/q/390056/211239

  [unshare.2]: https://man7.org/linux/man-pages/man2/unshare.2.html
  [clone.2]: https://man7.org/linux/man-pages/man2/clone.2.html
  [pivot_root.2]: https://man7.org/linux/man-pages/man2/pivot_root.2.html

  [OJSandbox]: {{ "/project/OJSandbox/" | relative_url }}
