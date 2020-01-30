#!/bin/bash

. ${0%/*}/util.sh
: ${SRC:=_site}

e_info "Patching generated site"

touch "$SRC/.nojekyll"
cat REMOTE_README.md > "$SRC/README.md"
if type jq &>/dev/null; then
  jq -S . < "$SRC/redirects.json" > /tmp/redirects.json
  mv /tmp/redirects.json "$SRC/redirects.json"
fi

e_success "Patch complete"
