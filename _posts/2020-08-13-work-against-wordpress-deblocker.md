---
title: "Working against WordPress DeBlocker plugin"
tags: web
redirect_from: /p/36

published: false
---

I'll go straight to the solution (keep in mind that it's considerably primitive, so use at your own risk) with code attached below. It's a [Tampermonkey][tampermonkey] userscript.

```javascript
// ==UserScript==
// @name         WordPress Anti-DeBlocker
// @version      0.1
// @author       iBug
// @match        *://*/*
// @license      MIT
// @grant        none
// @run-at       document-start
// ==/UserScript==

(function(document) {
    'use strict';

    const addEventListener_orig = document.addEventListener;
    document.addEventListener = function(a, b, c, d) {
        // a = event name (string), b = function
        var code = b.toString();
        if (a === "DOMContentLoaded" && code.match(/dev\W?tool/i)) {
            console.log("Blocked function. Code below");
            console.log(code);
            return;
        }
        addEventListener_orig(a, b, c, d);
    };
})(document);
```

## Encounter

I was searching for some resources when I came across a WordPress site. I had both ABP and uBO installed, and the website flashed blood red. So it was an ad blocker detector, easy peasy, and I hit Ctrl-Shift-I, only to find that it didn't work. I tried F12 and found it was blocked, too, so there must be other methods I could resort too.

## Getting F12 Developer Tools

If I can't open Dev Tools with the page showing, I can always have it open *before* the page loads. I had a sense this would be a tough opponent, so I opened an incognito window, enabled ad blocker extensions, opened Dev Tools, and navigated to the page.

![debugger paused](/image/wp-anti-deblocker/debugger-pause.png)

Whoa, it's paused with the debugger, and when I go to the Elements tab, I found that the script had removed the whole DOM, leaving only the `<html>` tag behind:

![empty dom](/image/wp-anti-deblocker/empty-dom.png)

That was **OUTRAGEOUS**! It's the most offensive script I've seen. I must track it down and counter it.

Looking at the **Network** tab, there are so many scripts that I probably can't inspect them one-by-one.

When I reload the page, I found that my whole Chrome went unresponsive, and I had to stop it from Task Manager. What a job they've done!

## Locating the script

One (and the only one so far) key behavior is its removal of the whole DOM, so if I could track that change, I could very accurately locate the offending script.

I opened Chrome in incognito mode again, and opened Dev Tools. I need to add a breakpoint on change to the root element, and I have to add the watcher after opening the page, so the first thing to do is to add a breakpoint at page load. I navigated to the **Sources** tab, under **Event Listener Breakpoints**, I checked `load`:

![breakpoint load](/image/wp-anti-deblocker/breakpoint-load.png)

Then I navigated to the page, and an innocent script hit the breakpoint.

![break at load](/image/wp-anti-deblocker/break-at-load.png)

That wasn't too much of a problem, as I could then switch to the **Elements** tab and add a breakpoint onto the `<html>` element:

![set breakpoint on html](/image/wp-anti-deblocker/set-breakpoint-on-html.png)

The next task would be a bit boring, to keep on continuing the debugger while keeping an eye on what's running.

![continue execution](/image/wp-anti-deblocker/continue-execution.png)

The same innocent script, along with jQuery, showed up around 20 times, before the first suspicious script poped up:

![first suspicious script](/image/wp-anti-deblocker/first-suspicious-script.png)

It was named `ads.min.js` and was pretty short, as shown below (formatted):

```javascript
"use strict";

let e = document.createElement("div");
e.id = "mdp-deblocker-ads";
e.style.display = "none";
document.body.appendChild(e);
```

So I let it continue.

It quickly became a tedious task, stepping through all those jQuery and analytics script with nothing interesting.

Recalling that the offending script would remove both `<head>` and `<body>` elements, I changed the breakpoint to them:

![set breakpoint on body](/image/wp-anti-deblocker/set-breakpoint-on-body.png)

It turned out that I did the right thing. Another suspicious script showed up very quickly:

![offending script found](/image/wp-anti-deblocker/offending-script-found.png)

It's minified and had a jumbled file name. Scrolling the line to the beginning shows a heavy hint that it's the one I was looking for:

![start of script](/image/wp-anti-deblocker/start-of-script.png)

Its comments pretty much told it all: *Most effective way to detect ad blockers*, so I pulled it out and took a closer look.

It wasn't hard to find some traits, for example, the following code is a part of it:

```javascript
throw ((checkStatus = "on"), new Error("Dev tools checker"));
```

## Tackling the vicious script

The script starts with an event listener:

```javascript
document.addEventListener(
  "DOMContentLoaded",
  function () {
      // function body
  },
  false
);
```

As I'm not particularly interested in disassembling the whole thing (you can always run it through a formatter to get a better idea of it), I decided to monkey-patch the event listener.

Because the script runs at a rather early stage of page load, I need to do something *even faster*, so it would be nice to run the "solution script" as soon as the page is "created". This can be done using Tampermonkey's `@run-on document-start` directive:

```javascript
// ==UserScript==
// @name         WordPress Anti-DeBlocker
// @run-at       document-start
// ==/UserScript==
```

Now I could write my logic and check what's being executed. Let's get `document.addEventListener` hooked up first:

```javascript
const addEventListener_orig = document.addEventListener;
document.addEventListener = function() {};
```

Looking at [the function prototype][addEventListener], it may have up to 4 arguments, so the patched function also needs to have 4:

```javascript
document.addEventListener = function(a, b, c, d) {};
```

It's not a good naming choice, but neither is it a must to have good coding styles here, so I'm going to pass it over here.

As shown by the code, it adds a listener to the `DOMContentLoaded` event, with its code containing `dev tools checker`. Knowing that the source code of a function can be retrieved with [`toString`][functionToString] method, I easily composed the following code:

```javascript
const addEventListener_orig = document.addEventListener;
document.addEventListener = function(a, b, c, d) {
    // a = event name (string), b = function
    var code = b.toString();
    if (a === "DOMContentLoaded" && code.match(/dev\W?tool/i)) {
        console.log("Blocked function. Code below");
        console.log(code);
        return;
    }
    addEventListener_orig(a, b, c, d);
};
```

The idea is simple: If something matching the known patterns of the target script, interrupt and deny its code.

The last thing is I need this countermeasure to run on all sites, so the `@match` directive should be the wildest wildcard:

```javascript
// ==UserScript==
// @name         WordPress Anti-DeBlocker
// @match        *://*/*
// @run-at       document-start
// ==/UserScript==
```

Now save the userscript and reload the page. I knew that my solution worked as soon as I saw the expected output:

![captured script](/image/wp-anti-deblocker/captured-script.png)

Well done, iBug! You've just got another achievement for defeating this plugin!

## The bottom line

While ads could be an important income for websites, there are users who detest them. Compelling every single and last user to disable their ad blocker for you is blunt and abusive. If you really want every piece of crummy money from your nasty ads, go fuck yourself.

Developer always wins.

I've uploaded the sample to <https://download.ibugone.com/wp-deblocker-2.0.3.js> for analysis (run it through VSCode formatter or `clang-format` first).

Finally, <a rel="nofollow noreferrer" href="https://1.envato.market/deblocker">here's the link</a> to the horrible WordPress plugin, if you want to find out for yourself.


  [tampermonkey]: https://www.tampermonkey.net/
  [addEventListener]: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
  [functionToString]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/toString
