---
title: "Bootstrapping Make"
description: null
tagline: "Using build automation tool"
tags: software development study-notes
redirect_from: /p/16
---

Have C or C++ project to build? You may think, "Yeah this is very easy, I'll just call the compiler to do so", and yes, let's take a look at an example.

# 1. Building a single C / C++ source file

If you have a bare minimum knowledge of calling a compiler from the command line, you would come up with such a command:

```shell
gcc -o hello hello.c
```

Yup, it's that simple, *for a single-file project*. What if there are two sources to be compiled together?

```shell
gcc -c -o hello.o hello.c
gcc -c -o main.o main.c
gcc -o hello hello.o main.o
```

If you still think it's easy, let's look at a slightly larger project with tens of sources and multiple output binaries:

```shell
gcc -c -o events.o events.c
gcc -c -o display.o display.c
...
...
gcc -c -o man.o main.c
gcc -c -o pager events.o display.o ...
gcc -c -o pager-config config.o ...
```

And that's when problems *se lèvent*. As you may have probably noticed, the last two commands have a wrong command argument `-c`, and the third-to-last command has a typo.
These kinds of small mostakes are very likely to happen during busily scrolling over command histories and changing the arguments, which is essentially repetitive work that's not for human.

As demonstrated above, manually typing the build commands might be feasible with projects with only one or two files, but you'll soon get tired typing them over and over again and start making mistakes if there are more files to be compiled and linked.

# 2. Basic build automation - shell scripts

You may feel that a script would be a better option and may come up with this:

```shell
#!/bin/sh

set -ex

build_obj() {
  gcc -c -o "$1".o "$1".c
}

link_bin() {
  OUT="$1"
  shift
  gcc -o "$OUT" "$@"
}

build_obj events
build_obj display
...
build_obj main
link_bin pager events.o display.o ... main.o
```

The above script, despite being plain and simple, is *at least* better than manually typing all the commands. But there are still issues with it.

Now you want to add a manpage and installation functionalities, and write them to the script:

```shell
...

build_manpage
install_manpage
```

That's a good move to add support for building manpage, but there's a serious caveat: there's probably no need to build the manpage and install it every time this build script is run, as well as everything else unchanged.

So, while it indeed is a better option than typing commands manually, it's still a bit distant from optimal. Here's when *Make* has its power.

# 3. Build automation with *Make*

*Make* is a software designed specifically for build automation. It follows a predefined build guideline, a `Makefile`, and builds your project.
What's more, Make offers more than simple build automation, like checking for changed files and only re-builds the changed files, eliminating redundant work spent on those unchanged files.

The first thing to using Make is knowing how to write a `Makefile`. Here's a basic `Makefile` for a single-file project:

```makefile
hello:
	gcc -o hello hello.c
```

And the command you'll run is just `make`. It will read your `Makefile` and compile `hello.c` into `hello` for you.

If you run `make` again immediately, it won't compile `hello.c` again, but tells you instead:

```text
make: Nothing to be done for 'all'.
```

You can see that Make avoids redundant work by checking for up-to-date files and skipping them.

An instruction to build a file is called a *target* in Makefile. In the above example, `hello` is a target and is the default target in the Makefile. Of course, you can have multiple targets in one Makefile:

```makefile
hello:
	gcc -o hello hello.c

hello_debug:
	gcc -g -o hello_debug hello.c
```

And when you run `make`, the first target in the Makefile is the default target. You can specify a target that you want Make to build by specifying it on the command line:

```shell
make hello_debug
```

Without Make or some other kind of build automation tool, resolving and carefully managing the dependency relationships among source files and intermediate files are a pain. With Make, it does this job for you.

A common type of dependency is linking object files into multiple output binaries. Here's an example that shows how Make manages dependencies:

```makefile
.PHONY: all

all: hello world

hello: library.o hello.o
	gcc -o $@ $^

world: library.o world.o
	gcc -o $@ $^

%.o: %.c
	gcc -O3 -Wall -c -o $@ $^
```

In the above example, both output programs `hello` and `world` depends on `library.o`. When you run `make`, you'll see Make compiles `library.o` first, and only once, and uses it to link both binaries. The variables `$@` and `$^` are called [Automatic Variables][1]. Make is also capable of resolving complex dependencies, as long as they don't form a loop. The `.PHONY` target is a [Phony target][2], which will be built regardless of the existence of a file with the very name. That says, if you don't write `.PHONY: all` and have an up-to-date file named `all` in your directory, Make won't build the `all` target again.

Make also supports variables so you don't have to write the same commands or arguments repeatedly. For example, the above `makefile` can be rewritten as follows:

```makefile
CFLAGS = -O3 -Wall

.PHONY: all

all: hello world

hello: library.o hello.o
	${CC} -o $@ $^

world: library.o world.o
	${CC} -o $@ $^

%.o: %.c
	${CC} ${CFLAGS} -c -o $@ $^
```

`${CC}` is an automatic variable provided by Make and defaults to `cc`. You can use another compiler by overriding this variable when invoking `make`:

```shell
make CC=clang
```

Here, `CC` is overridden with value `clang`, and all `${CC}` in the Makefile is substituted with `clang`, effectively calling the Clang compiler to compile the project. There are various ways of assigning variables, such as `=`, `:=`, `?=` and `+=`, all of which have different effects and usages.

You can find out more about Make by running `man make` on your system, or by referring to the [GNU `make` Manual][m] on GNU's website.


  [1]: https://www.gnu.org/s/make/manual/html_node/Automatic-Variables.html
  [2]: https://www.gnu.org/s/make/manual/html_node/Phony-Targets.html
  [m]: https://www.gnu.org/software/make/manual/make.html
