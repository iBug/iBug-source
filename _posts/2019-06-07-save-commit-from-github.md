---
title: "How I saved a lost commit from GitHub"
tags: git github study-notes
keywords: [git, github, commit, restore, recovery]
redirect_from: /p/20

toc: false
header:
  overlay_image: "/image/code.jpg"
---

Earlier today I force-pushed to my repository [USTC-RV-Chisel](https://github.com/iBug/USTC-RV-Chisel) for testing purposes,
without noticing that my local ref `origin/master` is 1 commit behind the actual `master` on GitHub.
My friend pushed his work (1 commit) to it, and now it's lost.

Fortunately, I haven't closed my terminal yet, so there's at least some place to look at:

![image](/image/git-restore/1.png)

From the terminal log, I knew that the SHA of the lost commit begins with `b3c3b36`, so it appeared very intuitive for me to just try fetching the commit, but no luck:

![image](/image/git-restore/2.png)

I recalled that GitHub can show commits with only first 7 digits of its SHA, so I constructed the URL <https://github.com/iBug/USTC-RV-Chisel/commit/b3c3b36> and followed it:

![image](/image/git-restore/3.png)

Now trying it again with the full SHA that's easily retrieved from the web page:

![image](/image/git-restore/4.png)

Hello? Does GitHub allow this? Oh-no!

I Googled around for a few minutes, and concluded that GitHub doesn't allow fetching this commit, because it's *unadvertised*.

Thinking around for ideas, I decided to give it a try to rebuild the commit.

First, I prepare my working directory with

    git add -A
    git stash
    git reset --hard ee216e3  # This is the parent commit of the lost commit

Then, I need the full content of the tree of the commit.

While GitHub offers ZIP archive download at the tree page <https://github.com/iBug/USTC-RV-Chisel/tree/b3c3b36>, ZIP isn't good for this job - it doesn't preserve POSIX file modes, so I looked around for the TAR archive (tarball). It wasn't on the page.

Thinking around again, I recalled working with the GitHub API, and there's an endpoint to get a tarball.
It wasn't hard to construct the desired GitHub API call URL:

    curl -v https://api.github.com/repos/iBug/USTC-RV-Chisel/tarball/b3c3b3683a6f5961dcde2d6c5312c31d9f382865

Looking at the cURL output, the `Location` header is what I wanted, so I followed it and `wget` the target:

    wget https://codeload.github.com/iBug/USTC-RV-Chisel/legacy.tar.gz/b3c3b3683a6f5961dcde2d6c5312c31d9f382865

The next thing was to examine the tarball to determine the top-level folder name:

![image](/image/git-restore/5.png)

To make it easier to merge my working directory with the tarball, I renamed my local folder to match the one in the tarball:

![image](/image/git-restore/6.png)

Now it's time to rebuild the commit!

Now that the working directory is restored, all that's left to do is to figure out the committer information and commit time.

I must say here that retrieving those information from the GitHub API is an easier way to do it programmatically, but since I had the browser page open as well as my local repository, fetching the exact time from the web page was the method easier to reach, and committer information can be seen from `git log`.

![image](/image/git-restore/7.png)

<sup>The exact time in ISO 8601 format is available through F12<sup>

With all the required information collected, I rebuilt the commit myself:

![image](/image/git-restore/8.png)

Look! The new commit has the same SHA as the lost commit! So they're the same commit now.

Pushing the restored commit back happily:

![image](/image/git-restore/9.png)
