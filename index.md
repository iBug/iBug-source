---
title: "iBug on the Web"
layout: splash
header:
  overlay_color: "#000"
  overlay_filter: "0"
  overlay_image: "/image/mm/splash.jpg"
  actions:
    - label: "<i class='fas fa-user-circle'></i> More"
      url: "/about"
  #caption: "Photo credit?"
excerpt: "The little personal website of iBug  \n&nbsp;"
#intro:
#  - excerpt: "Not applicable"
feature_row:
  - image_path: "/image/mm/blog.jpg"
    alt: "blog title"
    title: "Blogs"
    excerpt: "iBug is a casual, yet lazy blogger, and he occasionally writes something about his new discoveries."
    url: "/blog"
    btn_label: "<i class='fas fa-book-reader'></i> Read"
    btn_class: "btn--primary"
  - image_path: "/image/mm/projects.jpg"
    #image_caption: ""
    alt: "project image"
    title: "Projects"
    excerpt: "Projects that iBug has led or participated and proudly wanting to present you with."
    url: "/project"
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
    excerpt: "iBug is an avid user on Stack Overflow and has asked and answers a lot of questions. You're highly encouraged to checkout his profile on Stack Overflow."
    url: "https://stackoverflow.com/users/5958455/ibug"
    btn_label: "Go <i class='fas fa-arrow-circle-right'></i>"
    btn_class: "btn--primary"
---

{% comment %}
feature_row3:
  - image_path: /assets/images/unsplash-gallery-image-2-th.jpg
    alt: "placeholder image 2"
    title: "Placeholder Image Right Aligned"
    excerpt: 'This is some sample content that goes here with **Markdown** formatting. Right aligned with `type="right"`'
    url: "#test-link"
    btn_label: "Read More"
    btn_class: "btn--primary"
feature_row4:
  - image_path: /assets/images/unsplash-gallery-image-2-th.jpg
    alt: "placeholder image 2"
    title: "Placeholder Image Center Aligned"
    excerpt: 'This is some sample content that goes here with **Markdown** formatting. Centered with `type="center"`'
    url: "#test-link"
    btn_label: "Read More"
    btn_class: "btn--primary"
---

{% include feature_row id="intro" type="center" %}
{% endcomment %}

{% include feature_row %}

{% include feature_row id="stack_overflow" type="left" %}

{% comment %}

{% include feature_row id="feature_row3" type="right" %}

{% include feature_row id="feature_row4" type="center" %}
{% endcomment %}
