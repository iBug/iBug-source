---
title: "Friends"
comments: false
share: false

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
  - name: cvhc
    link: https://i-yu.me/
  - name: ksqsf
    link: https://ksqsf.moe/

net_friends:
  - name: ArtOfCode
    link: https://artofcode.co.uk/
---

*Ordered randomly*

{% for item in page.friends %}
- {{ item.name }}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }})
{% endfor %}

Other good folks online:

{% for item in page.net_friends %}
- {{ item.name }}\: [<i class="fas fa-globe-americas"></i> {{ item.link }}]({{ item.link }})
{% endfor %}

<style type="text/css">
ul { list-style-type: none; }
</style>
