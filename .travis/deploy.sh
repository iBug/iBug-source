#!/bin/bash

set -e

SRC=_site
LOCAL=remote

e_info() {
  echo -e "\x1B[36;1m[Info]\x1B[0m $*" >&2
}

e_success() {
  echo -e "\x1B[32;1m[Success]\x1B[0m $*" >&2
}

e_warning() {
  echo -e "\x1B[33;1m[Warning]\x1B[0m $*" >&2
}

e_error() {
  echo -e "\x1B[31;1m[Error]\x1B[0m $*" >&2
}

if [ -z "${GH_TOKEN}" ]; then
  e_error "GitHub token not set, not deploying"
  exit 1
fi

e_info "Cloning from GitHub"
git clone --depth=1 --branch=master "https://${GH_TOKEN}@github.com/iBug/iBug.github.io.git" "$LOCAL" &>/dev/null

e_info "Cleaning up local working directory"
cd "$LOCAL"
git rm -rf . &>/dev/null
cd ..

e_info "Moving generated site to git working directory"
mv -f "$SRC/"* "$LOCAL"
cd "$LOCAL"

e_info "Adding commit info"
#git config user.name "Travis CI"
#git config user.email "travis@travis-ci.org"
git config user.name "iBug-Bot"
git config user.email "37260785+iBug-Bot@users.noreply.github.com"
git add --all
git commit --message "Auto deploy from Travis CI build ${TRAVIS_BUILD_NUMBER}" &>/dev/null

e_info "Pushing to GitHub"
git remote add deploy "https://${GH_TOKEN}@github.com/iBug/iBug.github.io.git" &>/dev/null
git push deploy master &>/dev/null

e_success "Successfully deployed to GitHub Pages"
