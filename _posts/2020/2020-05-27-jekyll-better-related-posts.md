---
title: 'Enabling better "Related Posts" with Jekyll'
categories: tech
tags: jekyll
redirect_from: /p/37
---

There's a less-known feature of Jekyll that populates `related_posts` correctly with "related" posts, instead of the 10 latest posts when it's disabled by default.

## LSI

Back in October 2019 I gave this feature a try, but the first obstacle was that there weren't any documentations around it. I had to struggle through random Google results to find the solution.

Fortunately, it wasn't hidden or scattered around so terribly. Jekyll has an official plugin [classifier-reborn][1] to enable [LSI (latent semantic indexing)][2], so one can simply install the gem and get Jekyll's LSI feature running. The recommended way has always been adding requirements to your `Gemfile`, like this:

```ruby
gem "classifier-reborn"
```

And then refresh your dependency installation with `bundle install`. You can try building your site again with LSI enabled by appending `--lsi` to `jekyll build` command:

```shell
bundle exec jekyll build --lsi
```

Sit back and make yourself a cup of coffee, because what follows is going to *really slow*. For every 10 posts with 1000 words each, you're going to have to wait for a minute for Jekyll to build your site (measured on GitHub Actions). This grows terribly as for larger sites, each build could take more than 10 minutes.

The build time scared me off when I first tried with it.

## Improving the speed

Fortunately, there is GNU Scientific Library to help speed up the process. There's also a Ruby wrapper `gsl` for this.

To fully utilize the enhancements from GSL, a native library is required. On Ubuntu / Debian, this can be done by installing the package `libgsl-dev`. On macOS, `brew install gsl` will suffice. Then you can proceed to adding `gem "gsl"` to your `Gemfile`.

The results are delighting: GSL reduced the build time of this website from 75s to 3s on my local machine (i7-8850H, Ubuntu 20.04), and from nearly 3 minutes to 8 seconds on GitHub Actions.

<div class="notice--primary" markdown="1">
#### <i class="fas fa-lightbulb"></i> Note
{: .no_toc }

GitHub Pages doesn't support LSI natively. You'll have to build your site with a CI service (like GitHub Actions) and deploy manually.
</div>

Happy Jekylling!

Special thanks to this article <https://frankindev.com/2019/11/21/enable-related-posts-with-lsi/>.


  [1]: https://github.com/jekyll/classifier-reborn
  [2]: https://jekyll.github.io/classifier-reborn/lsi
