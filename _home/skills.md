---
title: "Skills"
toc: true
toc_sticky: false
---

Grading scale mechanism:

| Score | Explanation |
| ----- | ----------- |
|  10   | You literally have written a book. |
| 7 - 9 | Expert, go-to person on this technology. |
| 5 - 6 | Solid daily working knowledge. Highly proficient. |
| 3 - 4 | Comfortable working with this, have to check manual on some things. |
| 1 - 2 | Have worked with it previously but either not much, or rusty. |

(Copied from <https://www.cirosantilli.com/skills>, thanks Ciro!)

However, since I'm only an amateur CS student without too many years of *solid* development experiences
(without the word *solid*, I may say 8 years, but with it, I'd go with only 5 years, being conservative),
I'm very hesitant to give myself a single 5 score on anything,
because I still need to occasionally check manuals and documentations on many technologies I work with.
For this reason, instead of numbers, I'll show the scores with stars.
One ★ means one score (and it's also more intuitive to look at).

Ordered at my own discretion, what I deem more important goes first :)

{::options parse_block_html="true" /}

## Software Programming

<dl class="rating-table">
C++ #3#

: [Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bc%2B%2B%5D) (also my top tag as of May 2019)

  Reason for not giving a fourth score: I'm not particularly familiar with STL and I haven't participated in a scaled C++ project. This should be considered a downside as I'm familiar with C++ syntax and many sneaky language features (and that's where my Stack Overflow score under the \[c++\] tag primarily comes from).

C #4#

: [Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bc%5D) (also my second top tag as of May 2019) and [my <i class="fab fa-github"></i> repositories](https://github.com/search?utf8=%E2%9C%93&q=user%3AiBug+language%3Ac)

Python #4#

: [Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bpython%5D)

  Also long-term contributor to [SmokeDetector](https://github.com/Charcoal-SE/SmokeDetector), a mid-scale Python chatbot that detects spam and deletes them rapidly.

Bash #3#

: [Stack Overflow activity](https://stackoverflow.com/search?q=user%3A5958455+%5Bbash%5D) and [a collection of my gadgets](https://github.com/iBug/shGadgets) written in Bash or POSIX `sh`.

VBScript #3#

: [A vicious project](https://github.com/iBug/Vira-2) and [some gadgets](https://github.com/iBug/vbsGadgets).

SQL #1#

: Merely touched and played with. Built some projects with MariaDB. SQLite3 CLI utility is good for tampering game saves :)

Ruby #1#

: Barely touched Ruby, write short snippets to aid existing Ruby projects (my Jekyll website or other Rails apps)

Verilog #1#

: Learned from school courses *Digital Circuit labs* and *Computer Organization and Design labs*. Not practiced much

Scala / Chisel #1#

: Assigned a research on Chisel for performing particularly well in *Digital Circuit labs*, and have worked on a few entry-level projects ([my COD <i class="fab fa-github"></i> repo](https://github.com/iBug/COD-2019) and [this RISC-V project](https://github.com/iBug/USTC-RV-Chisel)).

Flash ActionScript #2#

: [A very addictive plane-shooting game](https://github.com/iBug/SpaceRider) when I wrote back when I was 14. ([Project home page](/SpaceRider))

The Web Trilogy (HTML/CSS/JavaScript) #2#

: [The ugly "previous" website](https://classic.ibugone.com) that I designed and wrote on my own. Also a few pages on this site contains short JS snippets serving for various purposes. jQuery included.

Go #1#

: Touched a little bit.

Regular expressions #5#

: The only item on this page that I dare claiming solid knowledge on. Still learned and practiced in the SmokeDetector project linked above.

## Tools and technologies

{: .rating-table }

Git #3#

: I was about to give myself a score of 5 on this when I realized that Ciro Santilli claimed the same score, but backed with [a huge tutorial](https://www.cirosantilli.com/git-tutorial/) he wrote on his own.
Then I reevaluated myself and gave a score of only 3 - I can't even write a fifth of Ciro's tutorial.

Linux #3#

: Daily working environment (WSL) with enough supporting knowledge. Ironically, I don't have a preferred desktop environment because I mostly work in CLI. I have a few Ubuntu and Debian servers that I maintain personally, including a <i class="fab fa-raspberry-pi"></i> Raspberry Pi.

  What about checking out [my tmux config](https://ibug.github.io/ext/conf/tmux.conf)?

Windows Desktop #4#

: Long since I was 12 I began to learn various configurations and tweaks (primarily the Registry) of Windows XP and Windows 7, which helped build my solid knowledge on Windows setup, maintenance and recovery.

  Still using a Windows laptop (by MSI) for day-to-day working, yet heavily relies on WSL.

Vim #3#

: My most-used text editor. With Vim coding is just so easy and I've always wondered why one would need VSCode or JetBrains stuff.

NGINX #2#

: Preferred HTTP server over Apache. Have some experiences configuring and tuning it, as well as web optimization. Best paired with Docker.

Docker #2#

: My favorite application deployment solution, but haven't got much experience with it. I also have private CIs running in Docker containers.

  Haven't yet touched Kubernetes.

LXC / LXD ([Linux Containers](https://linuxcontainers.org/) #2#

: Did [a project](/project/vlab) organizing LXD containers as VMs for students to do their course experiments on. Wrote a Django frontent with the help of `pylxd` library. Also manages a small cluster of LXD containers for own and friends' use.

Make #1#

: My preferred build automation system. Usually writes `Makefile` for personal projects.

## Other

{: .rating-table }

DNS #4#

: Have a deep understanding of how DNS works, and set up and maintained different kinds of DNS services (local recursive `dnsmasq` / authoritative-only `bind9`), and manages more than 8 domains and some server clusters on my own.

Computer Networking #3#

: CTO of [Linux User Group @ USTC](https://lug.ustc.edu.cn/) since 2019. We have a complex overlay network based on tinc as our intranet. We also help school staff with issues in our campus network. I have learned a lot from these experiences.

Hardware maintenance #3#

: I assembled several desktop computers, and I maintain all my hardware on my own, ranging from my laptop to my phones. I send them to repair shops only when I identify that I can't repair or replace it by myself.

  - I disassembled new laptop even on day 1 of purchase for an immediate upgrade (e.g. SSD 256 GB → 1 TB). (Dec 2018)
  - I replaced a broken screen of an old phone manually. (Oct 2016)
  - I dismantled a HDD to learn how it worked. (April 2016)
  - I assembled my first desktop computer from parts. (May 2014)

Cryptography #2#

: My speciality in CTF competitions.

<!-- Working around kramdown not recognizing &star; and &starf; -->
<!-- Moved, focus on content in this file -->
{% include skills_script.html %}
