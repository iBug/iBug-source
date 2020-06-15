#!/bin/bash

export CI=true LSI=true
bundle exec jekyll build --profile --trace
git clone --depth=1 --branch=master --single-branch https://github.com/iBug/image.git _site/image
rm -rf _site/image/.git
