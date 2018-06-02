---
title: Joining SmokeDetector
description: My first experience of joining the developer crew of an existing open-source project
date: 2018-03-14 10:29:30Z
tags: development
redirect_from: /p/3
---

After a plain request, an administrator of the SmokeDetector project added me under the *Developers* section of [their team member list][people], which indicates that I am a known personnel for contributing a non-trivial amount of code to the project.

# Starting off

The whole [SmokeDetector] project is written in Python 3, and is currently the #2 starred repository [tagged `spam` on GitHub][gh-spam]. They use flake8 for coding convention enforcement, which makes the code pretty readable to anyone new to the project.

I started from reading the part of the code that I can understand, and making trivial changes like changing the content of string literals, as I usually do with unfamiliar code or learning a new programming language. [My first pull request][1st] that actually changed some functionality was a not-so-hard bug fix: In the reason *mostly dots in {}*, it used to attempt to strip `<code>` blocks after stripping all HTML tags, when there was no code blocks to strip anymore. This way a lot of dots inside code blocks that should have been stripped were wrongly left intact, and counted towards "total number of dots". A lot of false positives were generated because in some code blocks, the density of dots was particularly high.

It wasn't hard to copy that function down and try running it locally. I only added a few print statements before I noticed the logical error and made some patch. Then I submitted it as a pull request and luckily, it did not take long for a maintainer to evaluate my patch and merge it.

# Continuing more

Sure. I kept submitting a steady stream of [pull requests][prs] since then, and most were small fixes/changes. They were mostly a few lines' changes or even only a few characters, yet they made sense. They vary from catching a missing keyword to [adding a handy new chat command][pr1634].

Some changes that I'm specifically proud of:

- [#1544][pr1544]: Whitelist a few common file extensions that are often linked to external code sources like GitHub or Pastebin. They used to be caught for *misleading link* a lot.
- [#1634][pr1634]: Add a new command `!!/scan` (though it's originally named `!!/checkpost`). This command instructs SmokeDetector to scan a post if it was missed earlier, or if the user isn't sure if it's spam and is hesitant to directly `!!/report` it. It has become more popular than the original `!!/report` command since it was introduced.
- [#1677][pr1677]: Show analyzed reasons for manually reported posts. The "why" part of a manually reported post used to have only one line like this:

  ```
  Post manually reported by *iBug* in *Charcoal HQ*
  ```
  After my patch, SmokeDetector now runs the post through all the tests and generates an analysis of the post, telling inspectors what reasons the post would have been caught for. See [this report][pr1677e1] for example.

- [#1723][pr1723]: A bug fix for another long-standing bug in message parsing due to Stack Exchange inserting invisible characters every 80 characters, for the purpose of line breaking (strange why can't they use CSS). There was [a previous attempt][pr1723p] that failed to fix this bug, and I reverted it by the way. The patch was verified to be working by later tests.

# Conclusion

There's no denying that it's an important skill to continue from others' code, as it's a case that every programmer has to face sooner or later. Try starting at some easier tasks like inspecting a small single-file program and understanding it, then advance to trying modifying a multi-file project and make your own comprehension. Every project is a new start and you'll soon learn your own way of joining another team of coders.


  [SmokeDetector]: https://github.com/Charcoal-SE/SmokeDetector
  [gh-spam]: https://github.com/topics/spam
  [req]: https://chat.stackexchange.com/transcript/message/43396360#43396360
  [prom]: https://github.com/Charcoal-SE/charcoal-se.github.io/commit/24b1933b25248537673f6941ed0ef46e3026f36e
  [people]: https://charcoal-se.org/people
  [flake]: http://flake8.pycqa.org
  [1st]: https://github.com/Charcoal-SE/SmokeDetector/pull/1441
  [prs]: https://github.com/Charcoal-SE/SmokeDetector/pulls?q=is%3Apr+author%3AiBug
  [pr1544]: https://github.com/Charcoal-SE/SmokeDetector/pull/1544
  [pr1634]: https://github.com/Charcoal-SE/SmokeDetector/pull/1634
  [pr1677]: https://github.com/Charcoal-SE/SmokeDetector/pull/1677
  [pr1677e1]: https://metasmoke.erwaysoftware.com/post/109767
  [pr1723]: https://github.com/Charcoal-SE/SmokeDetector/pull/1723
  [pr1723p]: https://github.com/Charcoal-SE/SmokeDetector/pull/1554
