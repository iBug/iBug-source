---
title: Build GitHub Pages with Travis CI
description: If you use a dedicated CI service, there'll be no more plugin restrictions.
tags: development github-pages
redirect_from: /p/4
---

I just set up my GitHub Pages to be built with Travis CI. It's amazing. &rarr; [<img src="https://travis-ci.org/iBug/iBug-source.svg?branch=master" alt="Build Status" style="display: inline-block; vertical-align: middle;" />](https://travis-ci.org/iBug/iBug-source)

This site is now automatically built with Jekyll and pushed to my GitHub Pages repository whenever I push a commit to the [source repository][src]. Some build information is available on an [About page][about] that I specifically designed for auditing purposes.

**Previous state**: A site that's previously hosted on GitHub Pages, with source files directly put in **_username_.github.io**, and uses one of [GitHub's official themes][3].

If you're using a gem-based theme, it's also OK, with only one extra line to add in a file.


# What's Travis CI? {#whats-travis}

From [Wikipedia][1]:

> Travis CI is a hosted, distributed continuous integration service used to build and test software projects hosted at GitHub.

You really should read the Wikipedia entry. It's comprehensive.

# OK, but why do I need it?

If you stand with [the small set of plugins][5] allowed on GitHub Pages and the limited functionality it provides, as well as the unavailability of any pre- or post-processing scripts put together by yourself, then you probably don't need this solution at all. **BUT**, if you need additional plugins, or have a custom script that you'd like to run before generating your Jekyll website, this is definitely an improvement over vanilla GitHub Pages.

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

If you use another gem-based Jekyll theme for your site, add it in the `group` block as a gem. After that, run `bundle install` to set up your GitHub Pages build environment. Bundler should not require root privileges so you don't need to prefix the command with `sudo`.

Done? Done. Now run `bundle exec jekyll build` and have some coffee. Jekyll should generate your site under the `_site` folder. You can also try it live with `bundle exec jekyll serve` and open `http://localhost:4000` in a browser. It's really simple, isn't it?

Oh yes, there's another small change to apply. Add these lines to your `_config.yml` if they aren't present. These settings are safe and won't change your site if you push them directly to GitHub, but will correct some errors (if present) in later builds.

```yaml
url: https://{yourname}.github.io
baseurl: /
```


# 2. Setting up Travis CI build {#setup-travis}

## Set up Travis CI

To set up Travis CI, you need to first register, and then tell Travis what to do. If you have already set up Travis CI for your other projects, you can skip this part.

Open <https://travis-ci.org> and click on the top-right corner. Select *Sign in with GitHub*. Grant permissions to Travis CI and you'll be redirected back to Travis. Flip the switch beside your repository name.

You can also go to the settings page of your repo and try them out. It's recommended that you turn on the option *Build only if .travis.yml is present*. Make sure *Build pushed branches* is turned on.

## Set up build settings {#setup-build}

Now you've set up Travis CI. You need to tell Travis how to build your site. Create a file named `.travis.yml` with the following content. Note the file name starts with a dot.

```yaml
language: ruby
cache: bundler
sudo: false

script: bundle exec jekyll build
```

The first two lines tell Travis that the project uses Ruby, and cache Ruby Bundler's installation, so your subsequent builds will be faster as Bundler won't have to actually install anything - it is correctly cached. The third line tells Travis that building the site does not require root privileges. The last line is your site's build script.

Commit and push the file to GitHub, and go to Travis CI. You'll see your site is being built by Travis. There may be a delay of up to half a minute before Travis detects your commit and builds it, so don't haste.

You'll see Travis's build log, including Jekyll's output. That's it. The site is built.


# 3. Use Travis to deploy to GitHub {#deploy-travis}

## Generating access token for Travis CI

Before you use Travis to deploy built site to GitHub directly, there's one thing to note: For user/organization pages, GitHub Pages can only be built from the `master` branch. Because of that, you need to push your sources to another branch like `source`, or another repository.

If you've pushed your sources to another branch of the same repository, you don't need to change anything on Travis CI. If you've pushed your sources to another repository, go to Travis CI and turn on the switch for that repo (and probably turn off the switch for your GH Pages repo).

To allow Travis to push to your repositories, we need to generate an access token for it. Go to [Personal Access Tokens][4] settings page and click *Generate new token*. Enter an identifiable name like "Travis CI", and tick the box beside `public_repo`. You can also tick other boxes but they won't be useful.

Click *Generate Token* below and you'll get your token. **Be careful not to expose it** because anyone will have push access to all your public repositories (and other privileges, if you checked the boxes) with that token. You can revoke it at any time.

Go to your build settings page on Travis CI. Scroll down and look for "Environment variables" section. Enter `GH_TOKEN` as the name, and your token as the value. Do **not** turn on "display value in build log".

## Setting up deployment {#setup-deployment}

We need a deploy script. It can be as simple as following:

```shell
#!/bin/sh

cd _site
git init
git config user.name "Travis CI"
git config user.email "travis@travis-ci.org"
git add --all
git commit --message "Auto deploy from Travis CI build $TRAVIS_BUILD_NUMBER"
git remote add deploy https://$GH_TOKEN@github.com/<yourname>/<yourname>.github.io.git >/dev/null 2>&1
git push --force deploy master >/dev/null 2>&1
```

Replace `<yourname>` with your GitHub username in the above script. Name the script `deploy.sh` in your repository.

Now tell Travis to call the deploy script after building your site. Add these lines to your `.travis.yml`:

```yaml
after_success:
  - chmod 777 deploy.sh
  - ./deploy.sh
```

Push the changes to GitHub and watch Travis CI. It'll build your site in a moment, and push the built site to your GitHub Pages repo.

Voila! You can now push changes to your sources to GitHub, and let Travis CI build it and deploy it for you.


# 4. Miscellaneous {#miscellaneous}

When building with Travis CI, it's much like a local environment. You are no longer restricted to use only [the supported plugins][5] on GitHub Pages. You can use an arbitrary RubyGems-based plugin by adding `gem "plugin-name"` into your Gemfile, in `group :jekyll_plugins`. Travis will fetch the plugins and build your site for you.

[Here][6]'s a list of awesome gem-based Jekyll plugins that you can try.



  [1]: https://en.wikipedia.org/wiki/Travis_CI
  [2]: https://en.wikipedia.org/wiki/Jekyll_(software)
  [3]: https://github.com/pages-themes
  [4]: https://github.com/settings/tokens
  [5]: https://help.github.com/articles/configuring-jekyll-plugins/
  [6]: https://github.com/planetjekyll/awesome-jekyll-plugins
  [src]: https://github.com/iBug/iBug-source
  [about]: {{ site.url }}/about
  [plugins]: https://github.com/iBug/iBug-source/blob/master/Gemfile
