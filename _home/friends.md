---
title: "Friends"
comments: false
share: false
header:
  overlay_image: /image/header/color-1.jpg
  overlay_filter: linear-gradient(rgba(0, 0, 0, 0.2), transparent)

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
  - name: amezzz
    github: bc-li
    link: https://bc-li.github.io/
  - name: myl7
    github: myl7
    link: https://myl.moe/
  - name: Showfom
    github: Showfom
    link: https://u.sb/
  - name: Hypercube
    github: Smart-Hypercube
    link: https://0x01.me/
  - name: cvhc
    link: https://i-yu.me/
  - name: ksqsf
    github: ksqsf
    link: https://ksqsf.moe/
  - name: Catoverflow
    github: Catoverflow
    link: https://c-j.dev/
  - name: MirageTurtle
    github: MirageTurtle
    link: https://mirageturtle.top/
  - name: jiegec
    github: jiegec
    link: https://jia.je/
    comment: from Tshinghua University
  - name: Harry Chen
    github: Harry-Chen
    link: https://harrychen.xyz/
    comment: from Tshinghua University

net_friends:
  - name: ArtOfCode
    github: ArtOfCode-
    link: https://artofcode.co.uk/
  - name: cyyself
    github: cyyself
    link: https://blog.cyyself.name/
  - name: H3arn
    description: "I suppose we all thought that, one way or another."
    link: "https://h3a.moe"
    github: H3arn
---

Friends:

{% for item in page.friends %}
- {{ item.name }}{% if item.github %} [<i class="fab fa-github"></i>](https://github.com/{{ item.github }}){% endif %}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }}){: rel="noopener{% if item.name == "loliw" %} nofollow{% endif %}" }{% if item.comment %} ({{ item.comment | markdownify | remove: '<p>' | remove: '</p>' | strip }}){% endif %}
{% endfor %}{: .friends-list }

Other good folks online:

{% for item in page.net_friends %}
- {{ item.name }}{% if item.github %} [<i class="fab fa-github"></i>](https://github.com/{{ item.github }}){% endif %}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }}){: rel="noopener" }
{% endfor %}{: .friends-list }

<style>.friends-list { list-style-type: none; padding-left: 1em; }</style>
