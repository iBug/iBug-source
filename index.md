---
title: iBug on the Web
layout: home
redirect_from: 
  - /main
  - /master
  - /readme
no_footer: true
top_nav: true
---


# [Latest blogs][blog]

<section class="post-panes">
{% assign post_count = 0 %}
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
  {% assign post_count = post_count | plus: 1 %}
  {% if post_count >= 2 %}
    {% break %}
  {% endif %}
{% endfor %}
</section>

---

# [Featured Projects][pp]

See [a good console Tetris game with AI playing][TetrisAI] of mine :)

---

# About me

My profile on Stack Overflow:

<center>
<a href="https://stackoverflow.com/users/5958455">
<img alt="Profile for iBug at Stack Overflow, Q&A for professional and enthusiast programmers" src="https://stackoverflow.com/users/flair/5958455.png" class="card" style="margin-top: 0.2rem;"/>
</a>
</center>

See my [questions][so-q] and [answers][so-a] on Stack Overflow, or view **a selected list** of my [questions][so-sq] and [answers][so-sa].

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

  [TetrisAI]: https://ibug.github.io/TetrisAI
  [blog]: /blog
  [pp]: /project
  [gh]: https://github.com/iBug
  [so]: https://stackoverflow.com/users/5958455/ibug "Profile for iBug at Stack Overflow, Q&A for professional and enthusiast programmers"
  [so-q]: https://stackoverflow.com/users/5958455/ibug?tab=questions "iBug's questions on Stack Overflow"
  [so-a]: https://stackoverflow.com/users/5958455/ibug?tab=answers "iBug's answers on Stack Overflow"
  [so-sq]: /so/selected-questions
  [so-sa]: /so/selected-answers
