---
title: "Converting DFA to Regular Expression"
tags: study-notes regular-expression
redirect_from: /p/27

mathjax: true
---

This post originated from Lab 1 of course *Compilers: Principles* that I'm currently taking, in which we were required to write a `flex` program to parse a subset of the C language. The multiline comment `/* */` was the most troublesome to handle for most of us (excluding me, for sure).

---

I'll assume you've already drawn a DFA for the multiline-comment structure, so here it is:

{% include figure image_path="/image/dfa-comment.png" alt="DFA for the multiline comment" %}

We're first going to turn it into "state transformation equations", so it looks like this:

$$
A = \texttt{/*}\ |\ A\texttt{[^*]}\ |\ B\texttt{[^*/]}
\\
B = A\texttt{*}\ |\ B\texttt{*}
\\
C = B\texttt{/}
$$

The first step we're taking is to realize that $A=S\ \|\ Aa$ is easily found to be equivalent to $A = Sa^*$, where the superscript asterisk means "repeat 0 or more times". So $B$ can be turned into

$$
B = A\texttt{**}^* = A\texttt{*}^+
$$

Again, the superscript plus means "repeat 1 or more times" as the same in PCRE.

Now it's time to substitute $B$ with its simplified expression:

$$
A =  \texttt{/*}\ |\ A\texttt{[^*]}\ |\ A\texttt{*}^+\texttt{[^*/]}
\\
C = A\texttt{*}^+\texttt{/}
$$

Note that there's a *distributive property* here, which described using symbols, is that $Aa\ \|\ Ab = A(a\|b)$, so now we have

$$
A = \texttt{/*}\ |\ A\ (\texttt{[^*]}\ |\ \texttt{*}^+\texttt{[^*/]})
$$

Applying the first transformation $A = S\ \|\ Aa = Sa^*$, we have

$$
A = \texttt{/*}\ (\texttt{[^*]}\ |\ \texttt{*}^+\texttt{[^*/]})^*
$$

Now there's no recursion in the new "state transformation equation", so we can substitute $A$ with this final expression and get the regular expression for $C$, the result we want:

$$
C = A\texttt{*}^+\texttt{/} =
\texttt{/*}\ (\texttt{[^*]}\ |\ \texttt{*}^+\texttt{[^*/]})^*\ \texttt{*}^+\texttt{/}
$$

Converting the above regular expression to code, we now have

```
C = \/\*([^*]|\*+[^*/])*\*+\/
```

[Try it online with RegEx101!](https://regex101.com/r/qAog6Z/1)

---

Now can you imagine how to use regular expressions to match multiples of 3 (base 10)? Yes, it's entirely possible. See [this fantastic article](https://www.quaxio.com/triple/) for details, which uses essentially the same techniques to convert a DFA (or a finite-state machine) to a regular expression that does the job.