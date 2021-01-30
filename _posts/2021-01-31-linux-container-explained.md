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
---

Since years ago, containers have been a hot topic everywhere. There are many container softwares like [Docker][docker], [Linux Containers][lxc] and [Singularity][singularity]. It's hard to say one *understand* what containers are without diving into all the gory details of them, so I decided to go on this exploration myself.

  [docker]: https://www.docker.com/
  [lxc]: https://linuxcontainers.org/
  [singularity]: https://sylabs.io/singularity/

The actual motivation was (quite) a bit different, though, as I was a TA of *Operating Systems (H)* in Spring 2020, and I wanted to bring a wave of innovation into the course labs, so I worked this out very early.

The contents in this article are listed in the Table of Contents <span class="wide-only">on the right</span><span class="nonwide-only">at the top of this page</span>. My implementation in my GitHub repository and the original lab documents (which is also written primarily by me, in Chinese) are linked right above.

My test environment is Ubuntu 18.04 LTS (Kernel 5.3, HWE 18.04). In case of any difference, you can consult Google for details.

If you want to find out the exact system calls involved in a command-line tool, [`strace`][strace] is your friend.

  [strace]: https://strace.io/

<div class="notice--warning" markdown="1">
#### <i class="fas fa-exclamation-triangle"></i> Code samples have a different license than this article
{: .no_toc }

While this article is licensed under the CC BY-SA 4.0 license, code samples and snippets are taken from the GitHub repository, which is licensed under [the GPL-3.0 license](https://github.com/iBug/iSpawn/blob/master/LICENSE).
</div>

## Experimenting with isolation {#experimenting}

Before we jump straight to writing code, let's warm ourselves up by playing with an existing, minimal container implementation, to get a better idea of our target.

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

You can then run `mount` without arguments to see the mount results.

```text
sysfs on /sys type sysfs (rw,relatime)
proc on /proc type proc (rw,relatime)
tmpfs on /dev type devtmpfs (rw,relatime)
tmpfs on /tmp type tmpfs (rw,relatime)
```

If you compare this with the mount points in your host system, you may notice something different.

```text
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
udev on /dev type devtmpfs (rw,nosuid,noexec,relatime,size=65895752k,nr_inodes=16473938,mode=755)
tmpfs on /run type tmpfs (rw,nosuid,nodev,noexec,relatime,size=13191916k,mode=755)
```

The extra flags (`nosuid,nodev,noexec`) control the behavior of the mount point. For example, `nosuid` means the set-uid bit will be ignored for entries under the mount point, while `noexec` prevents any execution of programs from inside.

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

The fourth parameter corresponds to the flags we discussed above. All applicable flags can be found in the man page for [`mount(2)`][mount.2].

Keep in mind that, however, the last parameter isn't entirely useless. It's simply not used for now, but it'll play a role later. (Actually, you may have noticed already. Good job for that.)
{#mount-data-parameter}

### Creating device nodes

Now that we have an empty `/dev` directory, we should populate it with some device nodes so that software expecting their presence could work. At a minimum, we need `null`, `zero`, `random` and `urandom`, but you can add `tty` and `console` if you want (these two are a bit different - you have been warned).

Device nodes are created with [`mknod(2)`][mknod.2], whose prototype is:

```c
int mknod(const char *path, mode_t mode, dev_t dev);
```

With a little research effort, we know we'll call it like this:

```c
mknod("/dev/something", S_IFCHR | 0666, makedev(MAJOR, MINOR));
```

To determine the device node numbers, you can take a look at the same nodes in the host system, using `ls -l` or `stat`. Don't worry, the numbers for special devices remain the same across Linux distros, [unlike BSD systems][bsd-node-ids]. It shouldn't take long before you come to this:

```c
mknod("dev/null", S_IFCHR | 0666, makedev(1, 3));
mknod("dev/zero", S_IFCHR | 0666, makedev(1, 5));
mknod("dev/random", S_IFCHR | 0666, makedev(1, 8));
mknod("dev/urandom", S_IFCHR | 0666, makedev(1, 9));
```

  [bsd-node-ids]: https://unix.stackexchange.com/a/354985/211239

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

## System call filtering

To ensure full control, we're using a whitelist for system calls. This means any unknown one will be rejected. So we'll start by creating a new "SecComp filter context", and set the default action to "reject". By "reject", we'll return "permission denied" when a process tries to call it.

```c
scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_ERRNO(1));
```

The `SCMP_ACT_ERRNO(1)` refers exactly to "respond with EPERM", which will be hit if no other filters apply.

### System call whitelist

We'll now add each "safe" system call to our filter and set it to "allowed". To save some time scratching your head examining each system call, we'll adopt [Docker's syscall whitelist][docker-syscalls]. Each system call will be wrapped in `SCMP_SYS` so it's turned into a suitable number used inside SecComp.

We need to add the whole big list of "general" system calls, plus some platform- or scenario-specific ones, namely, two special system calls for `amd64` platform, and a few others for system administration, since we've allowed `CAP_SYS_ADMIN` inside the container.

Use your favorite text processing toolstack to get the big list into a C-array so we can loop over, like [this](https://github.com/iBug/iSpawn/blob/master/syscall_allow.c):

```c
int allowed_syscalls[] = {
    SCMP_SYS(accept),
    SCMP_SYS(accept4),
    SCMP_SYS(access),
    // Many, many more...
    SCMP_SYS(waitpid),
    SCMP_SYS(write),
    SCMP_SYS(writev),
```

And then append these special ones we want to include as well:

```
    // amd64-specific required syscalls
    SCMP_SYS(arch_prctl),
    SCMP_SYS(modify_ldt),

    // CAP_SYS_ADMIN-specific syscalls
    SCMP_SYS(bpf),
    SCMP_SYS(clone),
    SCMP_SYS(fanotify_init),
    SCMP_SYS(lookup_dcookie),
    SCMP_SYS(mount),
    SCMP_SYS(name_to_handle_at),
    SCMP_SYS(perf_event_open),
    SCMP_SYS(quotactl),
    SCMP_SYS(setdomainname),
    SCMP_SYS(sethostname),
    SCMP_SYS(setns),
    SCMP_SYS(syslog),
    SCMP_SYS(umount),
    SCMP_SYS(umount2),
    SCMP_SYS(unshare)
};
```

Find the number of items included, and save it for easier later use.

```c
size_t allowed_syscalls_len = sizeof(allowed_syscalls) / sizeof(allowed_syscalls[0]);
```

We can then add each system call to our new SecComp filter as "allowed" with a simple loop:

```c
for (int i = 0; i < allowed_syscalls_len; i++) {
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, allowed_syscalls[i], 0);
}
```

### Loading SecComp filter

After our filter has been constructed, we can load it onto our process for it to take effect.

```c
seccomp_load(ctx);
```

And finally, release the workspace to avoid memory leaks.

```c
seccomp_release(ctx);
```

### Caveats {#seccomp-caveats}

#### Incompatible system calls

As I worked this out on an Ubuntu 18.04 environment, some newer system calls weren't available in my system headers, like the `io_uring`-related ones that are introduced in Linux 5.1. You can safely comment out any of them that your compiler complains about not recognizing. There shouldn't be too many of them if your environment is up-to-date, though.

#### Precautionary checking

As it's too common for one of the function calls to fail, I've added sanity checks for them. Here's the complete code of this part.

```c
int filter_syscall(void) {
    scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_ERRNO(1));
    if (ctx == NULL) {
        return -1;
    }
    for (int i = 0; i < allowed_syscalls_len; i++) {
        if ((errno = seccomp_rule_add(ctx, SCMP_ACT_ALLOW, allowed_syscalls[i], 0)) < 0) {
            return -1;
        }
    }
    if ((errno = -seccomp_load(ctx)) < 0) {
        return -1;
    }
    seccomp_release(ctx);
    return 0;
}
```

  [docker-syscalls]: https://github.com/moby/moby/blob/master/profiles/seccomp/default.json

## Resource restriction

The last part we'll visit is restricting container resources. Surely we don't want a container to overuse system resources like CPU or RAM and make the host system less stable. Linux Control Groups (Cgroups) is designed for efficient resource constraint that we're going to make use of. There are many "cgroup systems" for different aspects of system resources, including CPU, RAM and even disk I/O. Looks pretty neat, right?

Unlike other parts we've built so far, cgroup doesn't use system calls for setup and configuration, but a filesystem-based interface instead, like those in `/proc` or `/sys`. In fact, the cgroup control interface resides exactly under `/sys`, at `/sys/fs/cgroup`. With this interface, we read and write "files" to change configuration values, and create and delete directories to add or remove structures.

There are multiple cgroup "controllers" working on different aspects of system resources, each having a distinct tree structure under `/sys/fs/cgroup`. So first we'll examine what cgroup controllers are available:

```console
root@ubuntu:~# ls /sys/fs/cgroup
blkio        cpuacct  freezer  net_cls           perf_event  systemd
cpu          cpuset   hugetlb  net_cls,net_prio  pids        unified
cpu,cpuacct  devices  memory   net_prio          rdma
```

Here we're interested in some of them, namely, `blkio`, `cpu`, `memory` and `pids`.

Let's first take a look at `pids`. We'll create our own subtree to start with:

```console
root@ubuntu:~# mkdir /sys/fs/cgroup/pids/ispawn
root@ubuntu:~# ls /sys/fs/cgroup/pids/ispawn
cgroup.clone_children  notify_on_release  pid.events  tasks
cgroup.procs           pid.current        pid.max
```

It's easily imagined that `pid.max` controls the maximum number of PIDs in this subsystem, so let's write something to it:

```console
root@ubuntu:~# echo 16 > /sys/fs/cgroup/pids/ispawn/pid.max
```

To verify that it's working, make an attempt to exceed the limit. Open another shell and find its pid with `echo $$`. Write the number that you see (it's the PID of the new shell) to `/sys/fs/cgroup/pids/ispawn/cgroup.procs`. You can verify that the new process has been added to the subsystem by reading that `cgroup.procs` files out, and you'll see the PID you just written.

Now switch to the new shell and try spawning a lot of subprocesses, for example:

```shell
for i in {1..20}; do /bin/sleep 10; done
```

You can see the shell output as *Operation not permitted* for 5 to 6 times. This means it has hit the PID cap and fails to spawn more processes.

In our C-based container program, we'll do this in the parent process. The code is intuitively simple.

```c
mkdir("/sys/fs/cgroup/pids/ispawn", 0777);
FILE *fp = fopen("/sys/fs/cgroup/pids/ispawn/pid.max", "w");
fprintf(fp, "%d", 16);
fclose(fp);
FILE *fp = fopen("/sys/fs/cgroup/pids/ispawn/cgroup.procs", "w");
fprintf(fp, "%d", pid); // pid of the child process
fclose(fp);
```

We can now proceed to setting other limits:

- To reduce CPU shares, we write to `cpu/cpu.shares`. Because CPU shares are relative to each other and the system default is usually 1024, setting the value to 256 for our container gives it 1/4 as much CPU as other processes when the system load goes up. (It still gets more CPU when needed and when the system is more idle.)
- To limit memory usage, we write to `memory/memory.limit_in_bytes` (for userspace memory) and `memory/memory.kmem.limit_in_bytes` (for kernel memory).
  - However, this limits only physical memory usage, so when swap is present, memory gets swapped out onto disk when it hits the limit. To completely disable swap for our container, set `memory/memory.swappiness` to zero.
- To reduce disk I/O priority, we write to `blkio/weight`. This is relative to 100 so writing 50 will reduce its disk I/O priority to half.
- The last thing to note is that the tree hierarchies are independent among different cgroup controllers, so you have to create the same `ispawn` directory in *each* of them, and write `cgroup.procs` inside *each* of them.

<div class="notice--primary" markdown="1">
#### <i class="fas fa-fw fa-lightbulb"></i> Heads up
{: .no_toc }

The course lab at the time was based on Ubuntu 18.04 with Linux kernel 5.3 (18.04 HWE). The cgroup controllers in newer kernels may be very different from what's presented in this article. For example, with Linux 5.4 on Ubuntu 20.04, the keys in PID cgroup begins with `pids.` instead of `pid.`, and `blkio` has a completely different set of available keys. Make sure you examine the cgroup directories before copying and pasting code.
</div>

### Mounting cgroup controllers inside the container

To enable applications in our container to use cgroup controllers, we must mount them inside. Like how we mounted `/sys`, `/tmp` and other filesystems, we check the output of `mount` to determine how we're going to call `mount(2)`.

```text
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,pids)
```

Everything looks similar to what we've just done, but there's one different thing: There's no mount flag for `pids`.

Recalling [we skipped the last parameter of `mount`](#mount-data-parameter), now it's time to pick it back up. Fortunately, it isn't too complicated. For our use case, we can just pass the string `"pids"` to that parameter, and we swap the string for another to mount another cgroup controller. You can read the man page for [`cgroups(7)`][cgroups.7] about this, look for *Mounting v1 controllers*.

To mimic the monut points on our host system, we additionally mount a tmpfs at `/sys/fs/cgroup`, and remount this mountpoint as read-only after adding the controllers. The final result looks like this:

```c
void mount_cgroup(void) {
    int cgmountflags = MS_NOSUID | MS_NODEV | MS_NOEXEC | MS_RELATIME;
    // Mount a tmpfs first
    mount("none", "sys/fs/cgroup", "tmpfs", cgmountflags, "mode=755");

    // Prepare mount points
    mkdir("sys/fs/cgroup/blkio", 0755);
    mkdir("sys/fs/cgroup/cpu,cpuacct", 0755);
    mkdir("sys/fs/cgroup/memory", 0755);
    mkdir("sys/fs/cgroup/pids", 0755);

    // Mount cgroup subsystems
    mount("cgroup", "sys/fs/cgroup/blkio", "cgroup", cgmountflags, "blkio");
    mount("cgroup", "sys/fs/cgroup/cpu,cpuacct", "cgroup", cgmountflags, "cpu,cpuacct");
    mount("cgroup", "sys/fs/cgroup/memory", "cgroup", cgmountflags, "memory");
    mount("cgroup", "sys/fs/cgroup/pids", "cgroup", cgmountflags, "pids");

    // cpu and cpuacct need symlinks
    symlink("cpu,cpuacct", "sys/fs/cgroup/cpu");
    symlink("cpu,cpuacct", "sys/fs/cgroup/cpuacct");

    // Remount the tmpfs as R/O
    mount(NULL, "sys/fs/cgroup", NULL, MS_REMOUNT | MS_RDONLY | cgmountflags, NULL);
    return 0;
}
```

### A small problem with cgroup namespace

During my experiments, I noticed a strange issue where I could see the host cgroup hierarchies in my container implementation. It turns out that the cgroup "root" inside a cgroup namespace is the subtree the process belongs in when this cgroup namespace is created / isolated. Once the namespaces is created, its root is determined and fixed, even if the "root" process is moved into another subtree later.

This means the child process must be "moved" to the desired cgroup subtree before the cgroup namespace is isolated. This leaves us with two options:

1. The parent process moves itself to the target cgroup subtree before calling `clone()` with `CLONE_NEWCGROUP`
2. The parent process calls `clone()` without `CLONE_NEWCGROUP`, moves the child process to the target cgroup subtree, and then tells the child process to isolate the cgroup namespace.

It should be noted that with the second option, some kind of "syncing" is needed to avoid the child process going too quickly to perform the cgroup namespace isolation before the parent process finishes its job. It's easy to come up with a solution that just works: We can create a pipe between the processes, where the parent process can send something to tell the child process that it's ready.

With this in mind, the second option is actually [easier to implement][cc4dcb1], since there's another system call for isolating namespaces in-place (i.e. without creating a new process), that we put away earlier. It's `unshare(2)`. It's simple to use, too, just call `unshare(CLONE_NEWCGROUP)` when ready.

To verify that this issue is handled correctly, check the content in `/proc/1/cgroup`. The correct result should look like this, where every line ends with a single `/`:

```text
12:cpuset:/
11:rdma:/
10:blkio:/
9:pids:/
8:devices:/
7:net_cls,net_prio:/
6:memory:/
5:hugetlb:/
4:perf_event:/
3:cpu,cpuacct:/
2:freezer:/
1:name=systemd:/
0::/
```

With an incorrectly written container, certain lines may have an unexpected value, generally starting with `/../`, for example:

```text
12:cpuset:/
11:rdma:/
10:blkio:/../user.slice
9:pids:/../user.slice/user-0.slice/
8:devices:/
7:net_cls,net_prio:/
6:memory:/../user.slice/user-0.slice/
5:hugetlb:/
4:perf_event:/
3:cpu,cpuacct:/../user.slice
2:freezer:/
1:name=systemd:/
0::/
```

As explained above, these paths are "paths to the cgroup location of PID 1 relative to the 'root' of the cgroup namespace". When properly done, the PID 1 should have all of its cgroup hierarchies belonging at "root".

Don't be surprised to see the inconsistent lines from `/proc/1/cgroup`, as a process can be at different locations in different cgroup controllers.

  [cc4dcb1]: https://github.com/iBug/iSpawn/commit/cc4dcb1032e2a4d4fc57491cc904f126b719ba88

## Conclusion

Now here, at this point, we've gone through all technologies required for a functional and secure Linux container, although our "container" isn't necessarily functional and secure. It's going to be hard work examining and patching all the loopholes for the best security, if you'd like, but the fundamentals have been covered already so there won't be anything new.

There are two namespaces we've skipped in the beginning (three if you count `CLONE_NEWTIME`). They are slightly more complicated to set up and isn't necessary for a container, as Docker doesn't use User Namespaces and systemd-nspawn doesn't use Network Namespaces by default.

There are also more to consider if you want multiple containers to run simultaneously. One notable thing is that each should have a separete cgroup subtree. Avoiding mount point conflict in race conditions is another thing to take into account.

Should you want a ready-to-use example to play with, here's the complete code that I wrote, with some bells and whistles added: [<i class="fab fa-github"></i> iBug/iSpawn](https://github.com/iBug/iSpawn). Keep in mind that it's wrote for Ubuntu 18.04 and things could have been changed drastically, so it may not work in your system.

### Further reading

- **Linux containers in 500 lines of code** by *Lizzie Dixon* - <https://blog.lizzie.io/linux-containers-in-500-loc.html>
- Wikipedia articles on ...
  - [Linux Namespaces][linux-namespaces]
  - [Capability-based security](https://en.wikipedia.org/wiki/Capability-based_security)
  - [SecComp](https://en.wikipedia.org/wiki/Seccomp)
  - [Cgroups](https://en.wikipedia.org/wiki/Cgroups)
  - [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), which we didn't touch here


  [linux-namespaces]: https://en.wikipedia.org/wiki/Linux_namespaces
  [uts-system]: https://en.wikipedia.org/wiki/History_of_Unix
  [chw00t]: https://github.com/earthquake/chw00t
  [lazy-umount]: https://unix.stackexchange.com/q/390056/211239

  [unshare.2]: https://man7.org/linux/man-pages/man2/unshare.2.html
  [clone.2]: https://man7.org/linux/man-pages/man2/clone.2.html
  [mount.2]: https://man7.org/linux/man-pages/man2/mount.2.html
  [mknod.2]: https://man7.org/linux/man-pages/man2/mknod.2.html
  [pivot_root.2]: https://man7.org/linux/man-pages/man2/pivot_root.2.html
  [cgroups.7]: https://man7.org/linux/man-pages/man7/cgroups.7.html

  [OJSandbox]: {{ "/project/OJSandbox/" | relative_url }}
