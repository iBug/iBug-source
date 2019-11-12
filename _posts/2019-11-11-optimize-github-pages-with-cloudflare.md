---
title: "Make your GitHub Pages website faster with Cloudflare"
tags: github-pages cloudflare
redirect_from: /p/28
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

  The `TYO` key indicates that my request went through Fastly's Tokyo endpoint.

### Custom behavior of HTTP response {#http-settings}

If you host your site on vanilla GitHub Pages, there's not much you can do with HTTP response, like cache control and redirects. By default, GitHub Pages sets all expiration times for static assets to 10 minutes, but for sure you may want certain files to be cached for longer. Like me, I would like all images on my site to be cached for as long as possible, which is not possible with GitHub Pages on its own.

Cloudflare offers a variety of tweaks via Page Rules, so I could achieve my goal with a Page Rule setting:

![My Cloudflare setting for image caching](/image/cloudflare/image-caching.png)

Now instead of fetching an identical copy from GitHub Pages' origin server, browsers will now cache all image on my website for a year, and Cloudflare's CDN servers will cache my images for up to 30 days. Other available options include redirection and performance optimizations, and it's up to you to explore them all.

### More secure HTTPS settings

Some time ago, GitHub Pages didn't support HTTPS with custom domains, which was quite a downside for such a popular service. At that time, Cloudflare was almost the only option to add HTTPS support to your website. While now this is no longer the case, there're still some weaknesses and limitations, for example the lack of support for HSTS and the occasional failure of renewing an SSL certificate. With Cloudflare you can add HSTS headers to all responses coming from your website, further improving security.

## The setup

### Get your custom domain onto Cloudflare

Besides CDN, Cloudflare is also a fantastic DNS provider. To get started with Cloudflare, you'll first move your domain's DNS to Cloudflare. [Sign up](https://dash.cloudflare.com/sign-up) if you don't already have an account.

Next, you'll be prompted for the domain you want to add to Cloudflare. Enter the domain and Cloudflare will perform a quick scan of all records, and you can manually review them and add missing records, if any.

To enable Cloudflare CDN for domains under which you run a website, click the grey cloud icon so it becomes orange. This means that website will be proxied and delivered via Cloudflare, and its DNS record will instead resolve to some of Cloudflare's IPs.

That's all, isn't it simple? But wait, there's more that Cloudflare provides, and you can now explore all of them and see which fits your needs.

![Apps that Cloudflare provides](/image/cloudflare/apps.png)

### Using Page Rules

Let's turn our focus onto the Page Rules app. With Page Rules you can configure Cloudflare behavior on specific "routes", or URL patterns. One common use case is to create a permanent redirect from your `www` domain to your apex domain, or in the reverse direction.

For example, if I want to create a permanent redirect from `www.ibugone.com` to `ibugone.com`, I would create a Page Rule like this:

![Page Rule for 301 redirection from www.ibugone.com to ibugone.com](/image/cloudflare/page-rule-301.png)

And there's an aggressive image caching setting [described before](#http-settings). There are many Page Rule options for you to explore, and there are always one or more that fits your needs.

### Get the best out of Cloudflare {#more-features}

For newer webmasters, you might want to ensure **SSL / TLS** works as expected. The **Full** mode makes Cloudflare fetch original content from your website via HTTPS without validating the certificate on your server. For GitHub Pages this is the option you generally want, as GitHub Pages presents its default certificate for `*.github.io` if it doesn't have a certificate for your domain. This is good enough for your website behind Cloudflare.

You can also enable better security by enabling latest security features in **Edge Certificates** tab of the **SSL / TLS** app, where you can set the minimum SSL version (TLS 1.2 recommended) and enable automatic HTTPS redirection. This will not only make your website more secure to visitors, but also give you a boost in SEO, as modern search engines favor HTTPS websites over HTTP ones. Though, you might not want to jump straight to HSTS before you're absolutely ready (see [Cloudflare article](https://support.cloudflare.com/hc/en-us/articles/204183088-Understanding-HSTS-HTTP-Strict-Transport-Security-)).

- I have moved the entire `ibugone.com` domain onto HSTS and get it preloaded because I'm confident I can handle it.

You may also want to tune your website for better performance by changing the settings under the **Speed** app, for example enabling HTTP/2 and auto minifying.

## Further reading

- Cloudflare has [an official blog](https://blog.cloudflare.com/secure-and-fast-github-pages-with-cloudflare/) on introducing Cloudflare to GitHub Pages, and it's actually a start-from-scratch tutorial for creating a static website and then deploying Cloudflare CDN over it.
