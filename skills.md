---
title: "Skills"
layout: single
classes: wide
author_profile: true
comments: true
---

Grading scale mechanism:

| Score | Explanation |
| ----- | ----------- |
|  10   | You literally have written a book. |
| 7 - 9 | Expert, go-to person on this technology. |
| 5 - 6 | Solid daily working knowledge. Highly proficient. |
| 3 - 4 | Comfortable working with this, have to check manual on some things. |
| 1 - 2 | Have worked with it previously but either not much, or rusty. |

(Copied from <https://www.cirosantilli.com/skills/>, thanks Ciro!)

However, since I'm only an amateur CS student without too many years of *solid* development experiences (without the word *solid*, I'd say **8**, but with it, I'd go with **5**, being conservative), I'm very hesitant give myself a single 5 score on anything, because I still need to check manuals and documentations on almost every technology I work with.
For this reason, instead of numbers, I'll show the scores with stars. One &starf; means one score (and it's also more intuitive to look at).

Not necessarily ordered in any ranking.

{::options parse_block_html="true" /}

### Programming languages

<dl class="rating-table">
<dt>C++ #3#</dt>
<dd>
[Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bc%2B%2B%5D) (also my top tag as of May 2019)

Reason for not giving a fourth score: I'm not particularly familiar with STL and I haven't participated in a scaled C++ project. This should be considered a downside as I'm familiar with C++ syntax and many sneaky language features (and that's where my Stack Overflow score under the \[c++\] tag primarily comes from).
</dd>

<dt>C #4#</dt>
<dd>
[Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bc%5D) (also my second top tag as of May 2019)
</dd>

<dt>Python #4#</dt>
<dd>
[Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bpython%5D)

Also long-term contributor to [SmokeDetector](https://github.com/Charcoal-SE/SmokeDetector), a mid-scale Python chatbot that detects spam and deletes them rapidly.
</dd>

<dt>Bash #3#</dt>
<dd>
[Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bbash%5D)
</dd>

<dt>VBScript #3#</dt>
<dd>
[A vicious project](https://github.com/iBug/Vira-2) and [some gadgets](https://github.com/iBug/vbsGadgets).
</dd>

<dt>SQL #1#</dt>
<dd>
Merely touched and played with. Built some projects with MariaDB. SQLite CLI utility is good for tampering game saves :)
</dd>

<dt>Ruby #1#</dt>
<dd>
</dd>

<dt>Verilog #1#</dt>
<dd>
Learned from school courses "Digital Circuit labs" and "Computer Organization and Design labs".
</dd>

<dt>Flash ActionScript #2#</dt>
<dd>
[A very addictive plane-shooting game](https://github.com/iBug/SpaceRider) when I wrote back when I was 14. ([Project home page](/SpaceRider))
</dd>

<dt>The Web Trilogy (HTML/CSS/JavaScript) #2#</dt>
<dd>
[The ugly "previous" website](https://classic.ibugone.com) that I designed and wrote on my own. Also a few pages on this site contains short JS snippets serving for various purposes.
</dd>

<dt>Regular expressions #5#</dt>
<dd>
The only item on this page that I dare claiming solid knowledge on. Still learned and practiced in the SmokeDetector project linked above.
</dd>
</dl>

### Tools and technologies

<dl class="rating-table">
<dt>Git #3#</dt>
<dd>
I was about to give myself a score of 5 on this when I realized that Ciro Santilli claimed the same score, but backed with [a huge tutorial](https://www.cirosantilli.com/git-tutorial/) he wrote on his own.
Then I reevaluated myself and gave a score of only 3 - I can't even write a fifth of Ciro's tutorial.
</dd>

<dt>Linux CLI Usage #3#</dt>
<dd>
Daily working environment (WSL) with enough supporting knowledge. Ironically, I don't have a preferred desktop environment because I mostly work in CLI.

What about checking out [my tmux config](/ext/conf/tmux.conf)?
</dd>

<dt>Make #1#</dt>
<dd>
My preferred build automation system. Usually writes `Makefile` for personal projects.
</dd>
</dl>

<!-- Working around kramdown not recognizing &star; and &starf; -->

<script type="text/javascript">
function replaceStars() {
    $('dl.rating-table dt').each(function (item) {
        let text = $(this).text(), stars = parseInt(text.match(/#(\d+)/)[1]), i, s = "";
        for (i = 0; i < stars; i++)
            s += "\u2605";
        for (; i < 5; i++)
            s += "\u2606";
        $(this).text(text.replace(/#\d+#/, s));
    });
}

function defer(method) {
    // Poll for jQuery
    if (window.jQuery)
        method();
    else
        setTimeout(() => defer(method), 50);
}
defer(replaceStars);
</script>