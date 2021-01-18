#!/bin/bash

e_info() {
  printf "\x1B[36;1m[Info]\x1B[0m %s\n" "$*" >&2
}

e_success() {
  printf "\x1B[32;1m[Success]\x1B[0m %s\n" "$*" >&2
}

e_warning() {
  printf "\x1B[33;1m[Warning]\x1B[0m %s\n" "$*" >&2
}

e_error() {
  printf "\x1B[31;1m[Error]\x1B[0m %s\n" "$*" >&2
}
