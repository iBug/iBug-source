---
title: Build GitHub Pages with Travis CI
description: No more plugin restrictions!
tags: development github-pages
redirect_from: /p/4
---

I just set up my GitHub Pages to be built with Travis CI. It's amazing.

**Previous state**: A site that's previously hosted on GitHub Pages, with source files directly put in **_username_.github.io**, and uses one of [GitHub's official themes][3].

If you're using a gem-based theme, it's also OK, with only one extra line to add in a file.


# What's Travis CI? {#whats-travis}

From [Wikipedia][1]:

> Travis CI is a hosted, distributed continuous integration service used to build and test software projects hosted at GitHub.

You really should read the Wikipedia entry. It's comprehensive.

# 1. Setting up your workspace for local building {#setting-up}

[Jekyll][2] is written in Ruby, so of course you need Ruby to run Jekyll. Some dependencies of Jekyll may require other libraries before they can run.

To install necessary components for Jekyll to run, type this command in a terminal:

```
sudo apt install ruby ruby-dev
```

If you're running Fedora/RHEL/CentOS etc, replace `apt` with `yum`, or with `brew` if you're on a Mac that has Homebrew installed.

Ruby's package manager, RubyGems, should be installed along with Ruby in the above command. Type `gem` in your terminal and see if it shows up. If not, install any package that contains `rubygem` in the package name and try again.

Now we need Ruby Bundler for dependency resolution and handling. It should be installed with RubyGems:

```
gem install bundler
```

If `gem` complains about permission stuff, run the command again with `sudo`.

We're almost done! Just set up Jekyll and whatever GitHub Pages depends and you can build your site in GitHub flavor!

Create a file named `Gemfile` with the following content:

```ruby
group :jekyll_plugins do
    gem "github-pages"
end
```

After that, run `bundle install` to set up your GitHub Pages build environment. Bundler should not require root privileges so you don't need to prefix the command with `sudo`.

Done? Done. Now run `bundle exec jekyll build` and have some coffee. Jekyll should generate your site under the `_site` folder. You can also try it live with `bundle exec jekyll serve` and open `http://localhost:4000` in a browser. It's really simple, isn't it?

Oh yes, there's another small change to apply. Add these lines to your `_config.yml` if they aren't present. These settings are safe and won't change your site if you push them directly to GitHub, but will correct some errors (if present) in later builds.

```yaml
url: https://{yourname}.github.io
baseurl: /
```


# 2. Setting up Travis CI build {#setup-travis}

To set up Travis CI, we need to first register, and then tell Travis what to do. If you have already set up Travis CI for your other projects, you can skip the registering part.

Open <https://travis-ci.org> and click on the top-right corner. Select *Sign in with GitHub*.

To be continued...



  [1]: https://en.wikipedia.org/wiki/Travis_CI
  [2]: https://en.wikipedia.org/wiki/Jekyll_(software)
  [3]: https://github.com/pages-themes
