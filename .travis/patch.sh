#!/bin/bash

: ${SRC:=_site}

e_success() {
  echo -e "\x1B[32;1m[Success]\x1B[0m $*" >&2
}

e_info() {
  echo -e "\x1B[36;1m[Info]\x1B[0m $*" >&2
}

e_warning() {
  echo -e "\x1B[33;1m[Warning]\x1B[0m $*" >&2
}

e_error() {
  echo -e "\x1B[31;1m[Error]\x1B[0m $*" >&2
}

e_info "Patching generated site"

touch "$SRC/.nojekyll"
cat REMOTE_README.md > "$SRC/README.md"

e_success "Patch complete"
