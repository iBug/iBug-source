#!/bin/bash

e_info() {
  printf "\033[36;1m[Info]\033[0m %s\n" "$*" >&2
}

e_success() {
  printf "\033[32;1m[Success]\033[0m %s\n" "$*" >&2
}

e_warning() {
  printf "\033[33;1m[Warning]\033[0m %s\n" "$*" >&2
}

e_error() {
  printf "\033[31;1m[Error]\033[0m %s\n" "$*" >&2
}
