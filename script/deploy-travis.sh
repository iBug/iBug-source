#!/bin/bash

. ${0%/*}/config.sh
: ${SRC:=_site} ${BRANCH:=master}

set -e

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

if [ -z "$SSH_KEY_E" ]; then
  e_error "SSH key not found, not deploying"
  exit 1
fi
base64 -d <<< "$SSH_KEY_E" | gunzip -c > ~/.ssh/id_rsa
export SSH_AUTH_SOCK=none GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa"
ssh-keyscan -H "git.dev.tencent.com" >> ~/.ssh/known_hosts

source_msg="$(git log -1 --pretty="[%h] %B")"

pushd "$SRC" &>/dev/null
rm CNAME

e_info "Adding commit info"
# Since we're pushing to another host, we want to torch the history
rm -rf .git
git init
git remote add origin "git@git.dev.tencent.com:iBugOne/iBugOne.coding.me.git"
git config user.name "iBug"
git config user.email "iBug@users.noreply.github.com"
git add --all
git commit --quiet --message "Auto deploy from Travis CI build ${TRAVIS_BUILD_NUMBER:-?}" --message "$source_msg" &>/dev/null

e_info "Pushing to Coding.net"
git push origin +${BRANCH:-master} &>/dev/null

popd &>/dev/null
e_success "Successfully deployed to Coding Pages"
