---
title: "Bootstrapping Make"
description: null
tagline: "Using build automation tool"
tags: software development study-notes
redirect_from: /p/16

published: false
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
install_manpage
```

and while it indeed is, it's still a bit distant from optimal. Here's when *Make* has its power:
It follows a predefined build guideline, a *`Makefile`*, and builds your project.
What's more, *Make* offers more than simple build automation, like checking for changed files and only re-build the changed files, eliminating redundant work spent on those unchanged files.
