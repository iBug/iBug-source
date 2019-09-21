---
title: "iBug"
excerpt: "Developer, system administrator, geek"
layout: splash
classes: ["landing"]
header:
  overlay_image: "/image/mm/splash.jpg"
  actions:
    - label: "<i class='fas fa-user-circle'></i> About"
      url: "/about"
    - label: "<i class='fas fa-wrench'></i> Skills"
      url: "/skills"
  #caption: "Photo credit?"
feature_row:
  - image_path: "/image/mm/blog.jpg"
    alt: "blog title"
    title: "Blog"
    excerpt: "iBug is a casual, yet lazy blogger, and he occasionally writes something about his new discoveries."
    url: "/blog"
    btn_label: "<i class='fas fa-book-reader'></i> Read"
    btn_class: "btn--primary"
  - image_path: "/image/mm/projects.jpg"
    #image_caption: ""
    alt: "project image"
    title: "Projects"
    excerpt: "Projects that iBug has led or participated and proudly wanting to present you with."
    url: "/projects"
    btn_label: "<i class='fas fa-globe'></i> Explore"
    btn_class: "btn--primary"
  - image_path: "/image/mm/chinese.jpg"
    alt: "chinese language"
    title: "Chinese Content 中文内容"
    excerpt: |
      Looking for Chinese content?  
      寻找中文内容？
    url: "/cn"
    btn_label: "<i class='fas fa-th-list'></i> 查看"
    btn_class: "btn--primary"
stack_overflow:
  - image_path: "/image/stack-overflow.jpg"
    alt: "Stack Overflow"
    title: "Stack Overflow Activity"
    excerpt: "iBug is an avid user on Stack Overflow and has asked and answered a lot of questions. You're highly encouraged to checkout his profile on Stack Overflow."
    url: "https://stackoverflow.com/users/5958455/ibug"
    btn_label: "Go <i class='fas fa-arrow-circle-right'></i>"
    btn_class: "btn--primary"
---

{% include feature_row %}

{% include feature_row id="stack_overflow" type="left" %}

### Other links

{% comment %}
- [My telegram channel](https://t.me/ibugthought) where I share random ideas
{% endcomment %}

- My roommate, [<i class="fas fa-globe-americas"></i> TaoKY's personal site](https://blog.taoky.moe/)  
  (He writes Simplified Chinese, while I prefer English)

- And [<i class="fas fa-globe-americas"></i> websites](/friends) of my friends.

{% if jekyll.environment == "production" %}
{% unless site.china %}
If you're visiting from China, you can go to [this mirror site](https://cn.ibugone.com) for faster loading.
{% endunless %}
{% endif %}

<script>document.getElementById('page-title').insertAdjacentHTML('beforebegin', '<img src="/image/avatar.png" alt="iBug" class="avatar" itemprop="image" />');</script>
