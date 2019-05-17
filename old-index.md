---
title: null
layout: single
classes: wide
author_profile: true
redirect_from:
  - /main
  - /master
  - /readme
---

# [Latest blog][blog]

<section class="post-panes">
{% for post in site.posts %}
  {% if post.hidden %}
    {% continue %}
  {% endif %}
  {% assign post_preview = post.description | default: post.excerpt | strip_html %}
<article>
<h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
<p style="margin-top: 0.8em" class="post-meta">
  <span class="post-meta-date">
    {{ post.date | date: site.date_format }}
  </span>
  <span class="post-meta-tags">
    {% for tag in post.tags %} <a href="/tags/{{ tag }}" class="tag post-meta-tag">{{ tag }}</a> {% endfor %}
  </span>
</p>
<p>{{ post_preview }}</p>
</article>
  {% break %}
{% endfor %}
</section>

---

# [Featured Projects][pp]

[SmokeDetector][SmokeDetector], a community-driven bot that detects spam and reports it for rapid deletion.

And [a good console Tetris game with AI playing][TetrisAI] of mine :)

---

The correct way to handle exceptions in your development:

```javascript
try {
    something
}
catch(e) {
    window.open("stackoverflow.com/search?q=" + e.message);
}
```

---

# Friendly links

- [My Telegram channel](https://t.me/ibugthought), although updated infrequently
- My roommate, [TaoKY's personal site](https://taoky.github.io) (He writes Simplified Chinese, while I mostly prefer English)


<!-- Links Section -->

  [SmokeDetector]: https://github.com/Charcoal-SE/SmokeDetector
  [TetrisAI]: https://ibug.github.io/TetrisAI
  [blog]: /blog
  [pp]: /project
  [gh]: https://github.com/iBug
  [so]: https://stackoverflow.com/users/5958455/ibug "Profile for iBug at Stack Overflow, Q&A for professional and enthusiast programmers"
