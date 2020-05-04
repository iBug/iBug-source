#!/bin/bash

# Make the configuration
. script/config.sh || true
. script/util.sh || true
: ${GH_REPO:=iBug/iBug.github.io} ${BRANCH:=master}

set -e

e_info "Cloning from GitHub:$GH_REPO.git, branch=$BRANCH"

if [ -n "$SSH_KEY_E" ]; then  # Prefer SSH key
  mkdir -p ~/.ssh
  base64 -d <<< "$SSH_KEY_E" | gunzip -c > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ssh-keyscan github.com >> ~/.ssh/known_hosts
  SSH_AUTH_SOCK=none \
  GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa" \
  git clone --depth=3 --branch=$BRANCH --single-branch "git@github.com:$GH_REPO.git" _site
elif [ -n "$GH_TOKEN" ]; then
  # Suppress output to protect token
  git clone --quiet --depth=3 --branch=$BRANCH --single-branch "https://$GH_TOKEN@github.com/$GH_REPO.git" _site &>/dev/null
  e_info "Clone result: $?"
else
  e_error "No SSH key found and no GitHub token present, not continuing."
  exit 0
fi

e_success "Done"
