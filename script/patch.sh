#!/bin/bash

. "${0%/*}"/util.sh
: "${SRC:=_site}"

e_info "Patching generated site"

touch "$SRC/.nojekyll"
ruby "${0%/*}/generate-cname.rb"
cat REMOTE_README.md > "$SRC/README.md"
cp LICENSE* "$SRC/"

if command -v jq &>/dev/null; then
  e_info "Formatting redirects.json"
  jq -S . < "$SRC/redirects.json" > /tmp/redirects.json
  mv /tmp/redirects.json "$SRC/redirects.json"
fi

e_info "Generating Cloudflare Pages files"
STYLE=cloudflare ruby script/generate-redirects.rb
cat _data/headers.txt >> "$SRC/_headers"
cat _data/cfp-redirects.txt >> "$SRC/_redirects"

if command -v npx &>/dev/null && [ -e package.json ]; then
  e_info "Processing JavaScript and CSS"
  npx uglifyjs "$SRC"/assets/js/{main.min,clipboard,love}.js -c -m -o "$SRC"/assets/js/main.min.js
  npx postcss "$SRC"/assets/css/main.css --use autoprefixer --replace --no-map
fi

e_success "Patch complete"
