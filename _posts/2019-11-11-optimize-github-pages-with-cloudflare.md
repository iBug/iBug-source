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

## Further reading

- Cloudflare has [an official blog](https://blog.cloudflare.com/secure-and-fast-github-pages-with-cloudflare/) on introducing Cloudflare to GitHub Pages, and it's actually a start-from-scratch tutorial for creating a static website and then deploying Cloudflare CDN over it.
