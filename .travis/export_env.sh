#!/bin/bash

e_info() { echo -e "\x1B[36;1m[Info]\x1B[0m $*" >&2; }
e_warning() { echo -e "\x1B[33;1m[Warning]\x1B[0m $*" >&2; }
e_error() { echo -e "\x1B[31;1m[Error]\x1B[0m $*" >&2; }

CONFIG=_config.yml

vars=("$@")

e_info "Exporting environment variables"
echo "env:" >>$CONFIG
for var in "${vars[@]}"; do
  echo "  ${var}: ${!var}" >>$CONFIG
done
