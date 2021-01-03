---
title: "Friends"
comments: false
share: false

friends:
  - name: taoky
    github: taoky
    link: https://blog.taoky.moe/
  - name: volltin
    github: volltin
    link: https://volltin.com/
  - name: maglee
    link: https://0xcc.me/
  - name: Zihan Zheng
    github: zzh1996
    link: https://zhengzihan.com/
  - name: Sirius
    github: sirius1242
    link: https://sirius1242.github.io/
  - name: Mingliang Zeng
    github: mlzeng
    link: https://mlzeng.com/
  - name: totoro
    github: yuanyiwei
    link: https://yyw.moe/
  - name: myl7
    github: myl7
    link: https://myl.moe/
  - name: loliw
    github: RubyOcelot
    link: https://loliw.moe/
    comment: Borrowed a lot of design from my website `:)`
  - name: Hypercube
    github: Smart-Hypercube
    link: https://0x01.me/
  - name: cvhc
    link: https://i-yu.me/
  - name: ksqsf
    github: ksqsf
    link: https://ksqsf.moe/
  - name: jiegec
    github: jiegec
    link: https://jia.je/

net_friends:
  - name: ArtOfCode
    github: ArtOfCode-
    link: https://artofcode.co.uk/
---

*Ordered randomly*

{% for item in page.friends %}
- {{ item.name }}{% if item.github %} [<i class="fab fa-github"></i>](https://github.com/{{ item.github }}){% endif %}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }}){% if item.comment %} ({{ item.comment | markdownify | remove: '<p>' | remove: '</p>' | strip }}){% endif %}
{% endfor %}{: .friends-list }

Other good folks online:

{% for item in page.net_friends %}
- {{ item.name }}{% if item.github %} [<i class="fab fa-github"></i>](https://github.com/{{ item.github }}){% endif %}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }})
{% endfor %}{: .friends-list }

<style>.friends-list { list-style-type: none; padding-left: 1em; }</style>
