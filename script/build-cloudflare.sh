#!/bin/bash

git clone --depth=1 --branch=master --single-branch https://github.com/iBug/image.git image
rm -rf image/.git

SRC="https://raw.githubusercontent.com/iBug/iBug-source/master"
curl -so _headers "$SRC/_data/headers.txt"
curl -so _redirects "$SRC/_data/cfp-redirects.txt"
