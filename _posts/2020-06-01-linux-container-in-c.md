---
title: "Write your own Linux Container in C"
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

Long story short,
