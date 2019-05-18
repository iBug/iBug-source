#!/bin/bash

. ${0%/*}/util.sh
: ${SRC:=_site}

e_info "Patching generated site"

touch "$SRC/.nojekyll"
cat REMOTE_README.md > "$SRC/README.md"

e_success "Patch complete"
