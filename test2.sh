#!/usr/bin/env bash

CIRCLE_COMPARE_URL="https://github.com/feedyard/orb-common-pipeline-tasks/compare/56bcf095fb29...8bf617096b94"

COMMIT_RANGE=$(echo $CIRCLE_COMPARE_URL | sed 's:^.*/compare/::g')
echo "Commit range: $COMMIT_RANGE"

# only publish a major release if there are new jobs or commands
if ( git diff $COMMIT_RANGE --name-status | grep -e "M\tsrc/commands" -e "A\tsrc/jobs" ); then
export INTEGRATION_TAG=major
# publish a minor release if there are other changes to jobs or commands
elif ( git diff $COMMIT_RANGE --name-status | grep -e "src/commands" -e "src/jobs" ); then
export INTEGRATION_TAG=minor
# patch release if any changers to examples, executors, @orb.yml
elif ( git diff $COMMIT_RANGE --name-status | grep -e "src/examples" -e "src/executors" -e "src/@orb.yml" ); then
export INTEGRATION_TAG=patch
# otherwise, don't publish a release
else
export INTEGRATION_TAG=edit
fi

echo $INTEGRATION_TAG
