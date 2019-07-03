#!/bin/bash

cd "$(dirname "$0")"/..

update() {
  git remote update
  git reset --hard origin/master
  bundle check || bundle install
}

build() {
  JEKYLL_ENV=production bundle exec jekyll build
}

deploy() {
}

update
build || exit
deploy
