#!/bin/sh

. ${0%/*}/config.sh
. ${0%/*}/util.sh

if [ -r "_data/redirects.txt" ]; then
  cat _data/redirects.txt > _site/_redirects
fi

if [ -r "_data/headers.txt" ]; then
  cat _data/headers.txt > _site/_headers
fi

e_info "Generating Netlify _redirects file"
ruby script/generate-redirects.rb

e_info "Calling netlify-cli"
exec npx netlify deploy --prod
