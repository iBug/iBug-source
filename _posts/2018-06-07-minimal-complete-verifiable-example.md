---
title: "Minimal, Complete, Verifiable Example"
description: "A Stack Overflow help center article"
tags: stack-overflow
redirect_from: /p/8

show_view: true
view_name: "Stack Overflow"
view_url: "https://stackoverflow.com/help/mcve"
---

# How to create a Minimal, Complete, and Verifiable example

When asking a question about a problem caused by your code, you will get much better answers if you provide code people can use to reproduce the problem. That code should be…

- …Minimal – Use as little code as possible that still produces the same problem
- …Complete – Provide all parts needed to reproduce the problem
- …Verifiable – Test the code you're about to provide to make sure it reproduces the problem

## Minimal

The more code there is to go through, the less likely people can find your problem. Streamline your example in one of two ways:


1. **Restart from scratch.** Create a new program, adding in only what is needed to see the problem.  This can be faster for vast systems where you think you already know the source of the problem. Also useful if you can't post the original code publicly for legal or ethical reasons.
2. **Divide and conquer.** When you have a small amount of code, but the source of the problem is entirely unclear, start removing code a bit at a time until the problem disappears – then add the last part back. 

### Minimal *and* readable

Minimal does not mean *terse* – don't sacrifice communication to brevity. Use consistent naming and indentation, and include comments if needed to explain portions of the code.  Most code editors have a shortcut for formatting code – find it, and *use it!* ~~~Also, **don't use tabs** – they may look good in your editor, but they'll just make a mess on Stack Overflow.~~~

## Complete

Make sure all information necessary to reproduce the problem is included:

- Some people might be prepared to load the parts up, and actually try them to test the answer they're about to post.
- The problem might not be in the part you suspect it is, but another part entirely.

If the problem requires some server-side code as well as an XML-based configuration file, include them both. If a web page problem requires HTML, some JavaScript and a stylesheet, include all three.

## Verifiable

To help you solve your problem, others will need to verify that it *exists:*

- **Describe the problem.** "It doesn't work" is not a problem statement.  Tell us what the expected behavior should be.  Tell us what the exact wording of the error message is, and which line of code is producing it.  Put a brief summary of the problem in the title of your question.
- **Eliminate any issues that aren't relevant to the problem.** If your question isn’t *about* a compiler error, ensure that there are no compile-time errors. Use a program such as [JSLint](https://www.jslint.com/) to validate interpreted languages. [Validate](https://validator.w3.org/) any HTML or XML. 
- **Ensure that the example actually reproduces the problem!** If you inadvertently fixed the problem while composing the example but didn't test it again, you'd want to know that before asking someone else to help.

It might help to shut the system down and restart it, or transport the example to a fresh machine to confirm it really does provide an example of the problem.

For more information on how to debug your program so you can create a minimal example, <a href="https://stackoverflow.com/users/88656/eric-lippert">Eric Lippert</a> has a fantastic blog post on the subject: *[How to debug small programs](https://ericlippert.com/2014/03/05/how-to-debug-small-programs/)*.

<sub>You may have been told to include an MCVE by some helpful commentary, or perhaps even an MVCE if they were rushed; sorry for the initialisms, this is what they were referring to.</sub>
