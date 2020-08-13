---
title: "How to change email of your Nvidia account"
tagline: "Very simple front-end manipulation in fact"
categories: lifehacks
toc: false
redirect_from: /p/29
---

I recently retired a few old email addresses, and am currently going in a row to change email for accounts associated with those emails. Everything else went smoothly, with my Nvidia account being an exception - There wasn't an option to change it!

![no change option?!?](/image/nv-account/main-page.png)

My first idea was to Google for solutions, and the first few results were on the GeForce forum saying you need to contact supprt. I did so, and ended up being told that emails can only be changed once per account, and there's no more option to change it once more. What a terrible UX design!

I decided to give it a try to work around this. I first created another account and checked where the \[Change Email\] was located. Not any hard.

![the change button](/image/nv-account/change-button.png)

From a web developer's perspective, it's a must to open F12 Developer Tools and examine the button:

![the change button - examined](/image/nv-account/change-button-f12.png)

Then I switched back to my old account and examined the same part of HTML:

![no change button - examined](/image/nv-account/change-button-disabled-f12.png)

Now it seems clear to me: The last thing to do before succeeding is to purge that `display: none;` from the button. Double-click on the text and you can delete it with ease:

![remove display none](/image/nv-account/removing-style.png)

Voilà! You can now click it to change email for your Nvidia account. Why on earth did they decide that email can only be changed once per account? It sucks!
