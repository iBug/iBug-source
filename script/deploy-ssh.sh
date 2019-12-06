#!/bin/bash

. ${0%/*}/config.sh
. ${0%/*}/util.sh
: ${SRC:=_site} ${BRANCH:=master} ${COMMIT_MSG:="Auto deploy from Continuous Integration"}

set -e

if [ -z "${SSH_KEY_E}" ]; then
  e_error "No SSH key present in environment, not pushing."
  exit 1
fi

source_msg="$(git log -1 --pretty="[%h] %B")"

pushd "$SRC" &>/dev/null
e_info "Adding commit info"
git config user.name "iBug"
git config user.email "git@ibugone.com"
git add --all
git commit --message "${COMMIT_MSG}" --message "$source_msg" &>/dev/null

e_info "Pushing to GitHub"
SSH_AUTH_SOCK=none \
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa" \
git push origin ${BRANCH:-master}

popd &>/dev/null
e_success "Successfully deployed to GitHub Pages"
