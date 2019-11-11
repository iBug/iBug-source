---
title: "Make your GitHub Pages website faster with Cloudflare"
tags: github-pages cloudflare
redirect_from: /p/28

published: false
---

This September I employed Cloudflare to optimize my website (<https://ibugone.com>) in various aspects. It turned out to be a brilliant move and Cloudflare has proved to be a great service to have.

![Landing page of my website](/image/homepage.jpg)

## Benefits

### Faster site loading

While I haven't made strict benchmarks, people all over the world have reported that my website loads faster and smoother than before.

My website is a Jekyll-generated static site, hosted with [GitHub Pages](https://pages.github.com/). Currently (August 2019) GitHub provides 4 IPs that are actually behind Fastly CDN, making all GitHub Pages website rather fast already given Fastly's global point of presence (PoP).

- You can examine the `X-Served-By` header of the response from GitHub Pages servers to see which edge location your website is served from. For example:

  ```shell
  $ curl -v https://ibug.github.io/ -H 'Host: ibugone.com'
  ...
  X-Served-By: cache-tyo19946-TYO
  ...
  ```

### Custom behavior of HTTP response

If you host your site on vanilla GitHub Pages, there's not much you can do with HTTP response, like cache control and redirects. By default, GitHub Pages sets all expiration times for static assets to 10 minutes, but for sure you may want certain files to be cached for longer. Like me, I would like all images on my site to be cached for as long as possible, which is not possible with GitHub Pages on its own.

Cloudflare offers a variety of tweaks via Page Rules, so I could achieve my goal with a Page Rule setting:

![My Cloudflare setting for image caching](/image/cloudflare/image-caching.png)

Now instead of fetching an identical copy from GitHub Pages' origin server, browsers will now cache all image on my website for a year, and Cloudflare's CDN servers will cache my images for up to 30 days. Other available options include redirection and performance optimizations, and it's up to you to explore them all.

### More secure HTTPS settings

Some time ago, GitHub Pages didn't support HTTPS with custom domains, which was quite a downside for such a popular service. At that time, Cloudflare was almost the only option to add HTTPS support to your website. While now that this is no longer the case, there're still some weaknesses and limitations, for example the lack of support for HSTS and the occasional failure of renewing an SSL certificate. With Cloudflare you can add HSTS headers to all responses coming from your website, further improving security.

## The setup

### Get your custom domain onto Cloudflare

Besides CDN, Cloudflare is also a fantastic DNS provider. To get started with Cloudflare, you'll first move your domain's DNS to Cloudflare. [Sign up](https://dash.cloudflare.com/sign-up) if you don't already have an account.

## Further reading

- Cloudflare has [an official blog](https://blog.cloudflare.com/secure-and-fast-github-pages-with-cloudflare/) on introducing Cloudflare to GitHub Pages, and it's actually a start-from-scratch tutorial for creating a static website and then deploying Cloudflare CDN over it.
