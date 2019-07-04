---
title: "Friends"
layout: single
classes: wide
author_profile: true
comments: false
share: false
related: false
sidebar:
  nav: home

friends:
  - name: taoky
    link: https://blog.taoky.moe/
  - name: Volltin
    link: https://volltin.com/
  - name: Zihan Zheng
    link: https://zhengzihan.com/
  - name: Sirius
    link: https://sirius1242.github.io/
  - name: Hypercube
    link: https://0x01.me/
  - name: Mingliang Zeng
    link: https://mlzeng.com/
---

*Ordered randomly*

{% for item in page.friends %}
  {{ item.name }}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }})

{% endfor %}
