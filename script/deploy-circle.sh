#!/bin/bash

COMMIT_MSG="Auto deploy from CircleCI build ${CIRCLE_BUILD_NUM:-?}"
# Currently using GitHub Actions for deployment
#. ${0%/*}/deploy-ssh.sh
