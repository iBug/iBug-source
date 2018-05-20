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
{% for post in site.posts limit:2 %}
{% assign post_preview = post.description | default: post.tagline | default: post.excerpt %}
<article>
  <h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
  <p style="margin-top: 0.8em" class="post-meta">
    <time>{{ post.date | date: site.date_format }}</time>
    <span class="post-meta-tags">
      {% for tag in post.tags %} <a href="/tags/{{ tag }}" class="tag post-meta-tag">{{ tag }}</a> {% endfor %}
    </span>
  </p>
  <p>{{ post_preview }}</p>
</article>
{% endfor %}
</section>

---

# [Featured Projects][pp]

See [a good console Tetris game with AI playing][TetrisAI] of mine :)

---

# About me

Here are my profiles on other websites:

- [<img src="/image/so-icon.png" width="16" height="16" /> Stack Overflow][so]

  [<img alt="Profile for iBug at Stack Overflow, Q&A for professional and enthusiast programmers" src="https://stackoverflow.com/users/flair/5958455.png" class="card" style="margin-top: 0.2rem;"/>][so]

  See my [questions][so-q] and [answers][so-a] on Stack Overflow, or view **a selected list** of my [questions][so-sq] and [answers][so-sa].

---

The correct way to handle exceptions in your development:

```javascript
try {
    something
}
catch(e) {
    window.location.href =
    "stackoverflow.com/search?q=" + e.message;
}
```

---

Friendly links:

- My roommate, [TaoKY's personal site](https://taoky.github.io) (He writes Simplified Chinese, while I mostly prefer English)


<!-- Links Section -->

  [TetrisAI]: https://ibug.github.io/TetrisAI
  [blog]: https://ibug.github.io/blog
  [pp]: https://ibug.github.io/project
  [gh]: https://github.com/iBug
  [so]: https://stackoverflow.com/users/5958455/ibug "Profile for iBug at Stack Overflow, Q&A for professional and enthusiast programmers"
  [so-q]: https://stackoverflow.com/users/5958455/ibug?tab=questions "iBug's questions on Stack Overflow"
  [so-a]: https://stackoverflow.com/users/5958455/ibug?tab=answers "iBug's answers on Stack Overflow"
  [so-sq]: https://ibug.github.io/so/selected-questions
  [so-sa]: https://ibug.github.io/so/selected-answers
