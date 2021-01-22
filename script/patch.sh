#!/bin/bash

. "${0%/*}"/util.sh
: "${SRC:=_site}"

e_info "Patching generated site"

touch "$SRC/.nojekyll"
ruby "${0%/*}/generate-cname.rb"
cat REMOTE_README.md > "$SRC/README.md"
cp LICENSE* "$SRC/"

if command -v jq &>/dev/null; then
  jq -S . < "$SRC/redirects.json" > /tmp/redirects.json
  mv /tmp/redirects.json "$SRC/redirects.json"
fi

if command -v npx &>/dev/null && [ -e package-lock.json ]; then
  # Combine all JS files into one
  npx uglifyjs "$SRC"/assets/js/{main.min,clipboard,love}.js -c -m -o "$SRC"/assets/js/main.min.js

  npx postcss "$SRC"/assets/css/main.css --use autoprefixer --replace --no-map
fi

e_success "Patch complete"
