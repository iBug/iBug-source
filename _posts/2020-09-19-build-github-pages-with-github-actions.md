---
title: Build GitHub Pages with GitHub Actions
excerpt: Why use an external service when there's an in-house GitHub service?
tags: development github-pages
redirect_from: /p/37
---

<div class="notice--primary" markdown="1">
#### <i class="fas fa-fw fa-lightbulb"></i> Heads up
{: .no_toc }

I wrote [another article]({% post_url 2018-04-14-build-github-pages-with-travis-ci %}) two years ago about building with Travis CI, but from my experience in the past half year, GitHub Actions is, in all aspects, a better option than Travis CI.

You should also read that article if you're unfamiliar with [Jekyll][jekyll], as I won't be repeating common basics. This article will focus on GitHub Actions rather than building a Jekyll site in general.
</div>

Earlier this year, I switched my GitHub Pages build from CircleCI to GitHub Actions.

Yep, an article is missing for CircleCI, but why is it still needed? GitHub Actions is better than CircleCI in *almost* every aspect, except for its CPU that runs slightly slower than that of CircleCI.


## 1. Review

In [my previous article]({% post_url 2018-04-14-build-github-pages-with-travis-ci %}) on building with Travis CI, we went through the steps of setting up a local build environment for our Jekyll site. We set up a Ruby development environment, installed `gem` and `bundle`, wrote a `Gemfile`, and built the Jekyll site locally.

If you're not yet ready for this part, check out that article first. I'm going straight to the main content this time.


## 2. Setting up GitHub Actions {#setup-actions}

Getting GitHub Actions ready for building is *much* easier than Travis CI, as everything you need to do is to push a config file into `.github/workflows` directory of your repository.

If you're working on a forked repository, you may want to navigate to the "Actions" tab in your repository, and enable Actions there. Actions is disabled for forked repositories by default.

### Configure build settings {#setup-build}

You can use any name for the config file, but here I'll go with `build.yml`. Here's a minimal set of steps you'll need.

{% raw %}
```yaml
name: build
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-ruby@v1
      with:
        ruby-version: 2.7
    - name: Setup cache for Bundler
      id: cache
      uses: actions/cache@v2
      with:
        path: vendor/bundle
        key: ${{ runner.os }}-bundler-${{ hashFiles('Gemfile') }}
        restore-keys: |
          ${{ runner.os }}-bundler-
    - name: Install dependencies
      run: |
        bundle install --path=vendor/bundle
    - name: Build site
      run: bundle exec jekyll build --profile --trace
      env:
        JEKYLL_ENV: production
        JEKYLL_GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

Unlike Travis CI, all GitHub Actions builds run in an identical environment, while specific languages and software are loaded at runtime. This workflow contains 5 steps, with each step being:

1. **Clone and checkout the repository.** Contrary to Travis CI, GitHub Actions does not clone the repository automatically, as GitHub Actions is intended for more general purposes than only running Continuous Integrations.
2. **Setup Ruby development environment.** This one is obvious, since Jekyll is written in Ruby.
3. **Setup cache.** For the same reason as with Travis CI: Caching installed gems speeds up *subsequent* builds.
4. **Install dependencies.** Self-explanatory.
5. **Build site.** Same as above, self-explanatory.

The build process is mostly the same as on Travis CI, except that many steps that are automatically taken on Travis CI have to be written explicitly.


## 3. Deploy to GitHub {#deploy-actions}

### Access token

You've probably noticed that there's a {% raw %}`${{ secrets.GITHUB_TOKEN }}`{% endraw %} in the above GitHub Actions config. That's [a neat feature][github_token] GitHub provides. The main downside is that the token has access only to the repository the workflow is running on (as well as any other public resources). So if you want to push to a different repository, you'll still have to resort to creating your personal access token (PAT) for it.

To keep things simple, I'll assume you're pushing to the same repository for deployment, where the GitHub-provided token can be used.

### Setting up deployment {#setup-deployment}

The deploy script from the other Travis CI article is as follows (with names replaced, of course):

{% raw %}
```shell
cd _site
git init
git config user.name "GitHub"
git config user.email "noreply@github.com"
git add --all
git commit --message "Auto deploy from GitHub Actions build $GITHUB_RUN_NUMBER"
git remote add deploy https://${{ secrets.GITHUB_TOKEN }}@github.com/<yourname>/<yourname>.github.io.git >/dev/null 2>&1
git push --force deploy master >/dev/null 2>&1
```
{% endraw %}

Again, replace `<yourname>` with your GitHub username in the above script.

Now, instead of writing it to a file, we can add this script directly to the build config, as shown below:

{% raw %}
```yaml
    - name: Deploy site
      run: |
        cd _site
        git init
        git config user.name "GitHub"
        git config user.email "noreply@github.com"
        git add --all
        git commit --message "Auto deploy from GitHub Actions build $GITHUB_RUN_NUMBER"
        git remote add deploy https://${{ secrets.GITHUB_TOKEN }}@github.com/<yourname>/<yourname>.github.io.git >/dev/null 2>&1
        git push --force deploy gh-pages >/dev/null 2>&1
```
{% endraw %}

### Fixing issues with GitHub Actions

There are a few things to tackle, however, as GitHub Actions works differently than Travis CI.

First, the GitHub-provided token, for unknown reasons, could not trigger GitHub Pages deploys. This used to be the case[^1] but has since been (partially) fixed. Now it can trigger Pages for non-root commits to the Pages branch. A "root commit" is the sole commit on a new branch, like the one created by the above build script, which always initializes a new repository and creates a single commit for the contents. This Pages issue makes the above build script non-functional, and we need to fix it.

An easy solution is to fetch the target (deploy) branch, and add a commit on top of whatever's there already. So we modify the build script to include this fix:

{% raw %}
```yaml
    - name: Deploy site
      run: |
        cd _site
        git init
        git config user.name "GitHub"
        git config user.email "noreply@github.com"
        git remote add deploy https://${{ secrets.GITHUB_TOKEN }}@github.com/<yourname>/<yourname>.github.io.git >/dev/null 2>&1
        git fetch --depth=1 deploy gh-pages
        git reset --soft FETCH_HEAD
        git checkout -B gh-pages
        git add --all
        git commit --message "Auto deploy from GitHub Actions build $GITHUB_RUN_NUMBER"
        git push deploy gh-pages >/dev/null 2>&1
```
{% endraw %}

In this revised script, we first fetch the target branch, with depth set to 1 to avoid unnecessary downloads. Then we reset our "branch pointer" to the fetched branch (`FETCH_HEAD`), before finally adding our content as another commit on top of it.

### Fixing issues with GitHub Actions - Alternative approach

There's an alternative solution to this issue, by cloning the deploy repository beforehand (and remove `git init` from the deploy step).

Insert this "clone" step *before* the "build" step:

{% raw %}
```yaml
    - name: Prepare build
      run: |
        git clone -q --depth=1 --branch=gh-pages --single-branch --no-checkout \
          https://${{ secrets.GITHUB_TOKEN }}@github.com/<yourname>/<yourname>.github.io.git _site/
```
{% endraw %}

and change the deploy step to this:

{% raw %}
```yaml
    - name: Deploy site
      run: |
        cd _site
        git config user.name "GitHub"
        git config user.email "noreply@github.com"
        git add --all
        git commit --message "Auto deploy from GitHub Actions build $GITHUB_RUN_NUMBER"
        git push deploy gh-pages
```
{% endraw %}

An important note is that you should tell Jekyll to keep your `.git` folder in the `_site` directory when building your site. This can be done by adding the following settings to your `_config.yml`:

```yaml
keep_files: [.git]
```

I recall that Jekyll 4.0 has this setting emplaced by default, but can't find the reference for now, so I'm recommending that you explicitly write this into your config file even if you have Jekyll 4 locally (which you probably don't if you're using the `github-pages` gem). It's a good idea to write configurations explicitly, after all.

## Finally

Now then, why did I migrate my website build to GitHub Actions, if both Travis CI and CircleCI are running perfectly?

I chose so for the following reasons:

- It's free for public repositories, with unlimited total usage. One rarely hits the total usage quota, however, even with CircleCI, which has a monthly limit of 1,000 total run minutes.
    - CircleCI's limit applies at account level, and does not differentiate between public and private repositories.
- Better runtime environments, except for CPU power, which is only slightly slower that that on CircleCI.
    - Boots faster, runs faster, more memory
- It's provided by GitHub and hosted by Microsoft Azure, which may be more trustable than Travis CI and CircleCI for some users.
- One less external service to depend on. No more need to log into a separate website to review logs.
- ... and more

The primary downside compared to Travis CI is increased build config complexity, but on the other hand it adds more flexibility to your build patterns, which reciprocates.

But the most important thing to note is that whatever others tell, you should try and find the one most suitable for you.



  [^1]: https://github.community/t/github-action-not-triggering-gh-pages-upon-push/16096
  [jekyll]: https://jekyllrb.com/
  [src]: https://github.com/iBug/iBug-source
  [about]: {{ "/about" | relative_url }}
  [plugins]: https://github.com/iBug/iBug-source/blob/master/Gemfile
  [github_token]: https://docs.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token