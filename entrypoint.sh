#!/bin/bash -eix

# GITHUB_EVENT_PATH=/tmp/abc.json

PR_REF=$(jq -r .ref < "${GITHUB_EVENT_PATH}")
PR_HEAD=$(basename "${PR_REF}")

PR_BASE=$(echo "${PR_HEAD}" | sed -E 's@pr_([a-zA-Z0-9]+)_.*@\1@g')
# 应该是pr_${TO_BRANCH}_other
if [[ -z "${PR_BASE}" ]];then
  echo "Not a pr request branch, should be pr_${PR_BASE}_other: ${PR_HEAD}"
  exit 0
fi


PR_TITLE=$(jq -r .head_commit.message < "${GITHUB_EVENT_PATH}")
if [[ -z "${PR_TITLE}" ]];then
  echo "No commit found, exit"
  exit 1
fi

PR_BODY=$(jq -r '.commits|map(.message)|join("<br>")' < "${GITHUB_EVENT_PATH}")
PR_URL=$(jq -r '.repository.pulls_url' < "${GITHUB_EVENT_PATH}"|sed 's@{.*}@@g')


generate_post_data()
{
  cat <<EOF
{
  "title": "${PR_TITLE}",
  "body": "${PR_BODY}",
  "head": "${PR_HEAD}",
  "base": "${PR_BASE}"
}
EOF
}


curl \
      --fail \
      -X POST \
      --data "$(generate_post_data)" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${PR_URL}"