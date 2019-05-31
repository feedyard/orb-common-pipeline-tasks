#!/usr/bin/env bash

FOUND_BASE_COMPARE_COMMIT=false
echo $FOUND_BASE_COMPARE_COMMIT

# start iteration from the job before $CIRCLE_BUILD_NUM
JOB_NUM=$(( $CIRCLE_BUILD_NUM - 1 ))
echo $JOB_NUM

## UTILS
extract_commit_from_job () {
  # abstract this logic out, it gets reused a few times
  # takes $1 (VCS_TYPE) & $2 (a job number)
  curl --user $CIRCLE_TOKEN: \
    https://circleci.com/api/v1.1/project/$1/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$2 | \
    grep '"vcs_revision" : ' | sed -E 's/"vcs_revision" ://' | sed -E 's/[[:punct:]]//g' | sed -E 's/ //g'
}




# determine VCS type, so we don't worry about it later
if ( echo $CIRCLE_REPOSITORY_URL | grep github.com ); then
  VCS_TYPE=github
else
  VCS_TYPE=bitbucket
fi

until ( $FOUND_BASE_COMPARE_COMMIT == true )
do
  # save circle api output to a temp file for reuse
  curl --user $CIRCLE_TOKEN: https://circleci.com/api/v1.1/project/$VCS_TYPE/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$JOB_NUM > JOB_OUTPUT


    if ( ! grep "\"workflow_id\" : \"$CIRCLE_WORKFLOW_ID\"" JOB_OUTPUT ) && \
      # 2. make sure job is not a retry of a previous job
      ( grep '"retry_of" : null' JOB_OUTPUT ) && \
      # 2.5 make sure job is not from a rerun workflow (same commit)
      ! $(grep "\"vcs_revision\" : \"$CIRCLE_SHA1\"" JOB_OUTPUT) && \
      # make sure we are on the same branch as $CIRCLE_BRANCH
      # (we've already ruled out that this is a brand-new branch)
      ( grep "\"branch\" : \"$CIRCLE_BRANCH\"" JOB_OUTPUT ); then
      echo "----------------------------------------------------------------------------------------------------"
      echo "success! job $JOB_NUM was neither part of the current workflow, part of a rerun workflow, a retry of a previous job, nor from a different branch"
      echo "----------------------------------------------------------------------------------------------------"
      FOUND_BASE_COMPARE_COMMIT=true
    else
      echo "----------------------------------------------------------------------------------------------------"
      echo "job $JOB_NUM was part of the current workflow, part of a rerun workflow, a retry of a previous job, or from a different branch"
      echo "----------------------------------------------------------------------------------------------------"
      JOB_NUM=$(( $JOB_NUM - 1 ))
      continue
    fi

done

rm -f JOB_OUTPUT
BASE_COMPARE_COMMIT=$(extract_commit_from_job $VCS_TYPE $JOB_NUM)
# construct our compare URL, based on VCS type
if [[ $(echo $VCS_TYPE | grep github) ]]; then
  CIRCLE_COMPARE_URL="https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/compare/${BASE_COMPARE_COMMIT:0:12}...${CIRCLE_SHA1:0:12}"
else
  CIRCLE_COMPARE_URL="https://bitbucket.org/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/branches/compare/${BASE_COMPARE_COMMIT:0:12}...${CIRCLE_SHA1:0:12}"
fi
echo "----------------------------------------------------------------------------------------------------"
echo "base compare commit hash is:" $BASE_COMPARE_COMMIT
echo ""
echo $BASE_COMPARE_COMMIT > BASE_COMPARE_COMMIT.txt
echo "this job's commit hash is:" $CIRCLE_SHA1
echo "----------------------------------------------------------------------------------------------------"
echo "recreated CIRCLE_COMPARE_URL:"
echo $CIRCLE_COMPARE_URL
echo "----------------------------------------------------------------------------------------------------"
echo "outputting CIRCLE_COMPARE_URL to a file in your working directory, called CIRCLE_COMPARE_URL.txt"
echo "(BASE_COMPARE_COMMIT has also been stored in your working directory as BASE_COMPARE_COMMIT.txt)"
echo $CIRCLE_COMPARE_URL > CIRCLE_COMPARE_URL.txt
echo "----------------------------------------------------------------------------------------------------"
echo "next: both CIRCLE_COMPARE_URL.txt and BASE_COMPARE_COMMIT.txt will be persisted to a workspace, in case they are needed in later jobs"
