#!/bin/bash

COMMIT_MSG="Auto deploy from CircleCI build ${CIRCLE_BUILD_NUM:-?}"
. ${0%/*}/deploy-ssh.sh
