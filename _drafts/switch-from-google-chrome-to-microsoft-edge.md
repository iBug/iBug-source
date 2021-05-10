---
title: "I switched from Google Chrome to Microsoft Edge"
tags: software web
redirect_from: /p/43
header:
  overlay_image: /image/header/mountain-2.jpg
  overlay_filter: linear-gradient(rgba(0, 0, 0, 0.2), transparent)
---

Last year (maybe September? I don't remember now) I switched my primary browser from Google Chrome to the new Microsoft Edge. It turned out to be a wise move and I've been with Edge for more than half a year now. I'll share my ideas with this move.

## What I thought before I switched {#thoughts-before}

### Same Chromium kernel

The moment Microsoft Edge went attractive was when I learned that [**it started to be based on Chromium**][1], so that web pages will behave identially as if they were on Google Chrome or the Chromium browser. This is particularly important as I often engineer for Chrome when developing front-end applications.

  [1]: https://www.browserstack.com/blog/chromium-based-edge/

Beside that, the seamless availability of existing Chrome extensions is also a great plus. I rely heavily on several extensions to enhance my surfing experience, some of which are:

- [Tampermonkey](https://microsoftedge.microsoft.com/addons/detail/tampermonkey/iikmkjmpaadaobahmlepeloendndfphd)
- [uBlock Origin](https://microsoftedge.microsoft.com/addons/detail/ublock-origin/odfafepnkmbhccpbejgmiehpchacaeak)
- Proxy SwitchyOmega
- [HTTPS Everywhere](https://microsoftedge.microsoft.com/addons/detail/https-everywhere/fchjpkplmbeeeaaogdbhjbgbknjobohb)

### Integration with Windows {#windows-integration}

As for everything else designed for or ships with Windows, Microsoft Edge integrates excellently into Windows and other Microsoft online products.

You can log in to Microsoft Edge with your Microsoft account with just one click, if you have the account set up with your Windows user. Then the syncing launches automatically, and your saved bookmarks, histories, forms etc. are readily available.

A logged-in Microsoft Edge browser also eases the login process of most Microsoft products, like Office Online, OneDrive, or whatever web application using Microsoft OAuth login. As long as the browser is authenticated, the `login.microsoftonline.com` page proceeds automatically. This comes in handy when you want to maximize your operation on the web.

### Data Syncing

Since I'm already using OneDrive for my document storage and syncing, I feel my data safer with Microsoft, and so does my browser information. Just like Google Chrome, the new Microsoft Edge syncs everything across computers and mobile devices. For the best connected experience, I also fetched Microsoft Edge (Android) from Google Play Store and signed in there. This enabled me to continue where I left off from my computer right on my phone.

### Better performance

Microsoft Edge, as promised, eats around 20% to 30% less memory than Google Chrome under the same load. This may not be a problem for beefy workstations with a lot of memory, but it surely plays a role in common househeld desktops and laptops. At a minimum, even if you don't need to keep more tabs at the same time, the extra memory allows you to run other applications, or simply gives the computer a breath.

## Disadvantages

Being relatively new as a consumer product, the new Microsoft Edge is still distant from perfection. There are quite a number of bugs or incomplete functionalities to spot.

### Missing favicons

The first thing it should fix is loading favicons for Favorites website. **It doesn't, at all.** With a newly imported Favorites library from another browser, **all favicons are missing**. On contrary, Google Chrome tries to load as many as possible after importing bookmarks, which is usually done in a few minutes. This makes the initial setup particularly bothersome, as you now have to read every bookmark title to determine its target, when you *could have* done so just by skimming through the icons.

![image](/image/microsoft-edge/missing-favicons.png)
