#!/usr/bin/env bash
set -euo pipefail

protected='^refs/heads/(main|master)$'

fail() {
    cat >&2 << 'MSG'
ERROR: Direct pushes to 'main' and 'master' are not allowed.

This repository uses a branch-based workflow:

  1. Create a feature branch:   git switch -c feat/my-change
  2. Commit using Conventional Commits (feat:, fix:, docs:, ...)
  3. Push the branch and open a pull request
MSG
    exit 1
}

if [[ -n "${PRE_COMMIT_REMOTE_BRANCH:-}" ]]; then
    if [[ "${PRE_COMMIT_REMOTE_BRANCH}" =~ ${protected} ]]; then
        fail
    fi
else
    while read -r _local_ref _local_sha remote_ref _remote_sha; do
        if [[ "${remote_ref}" =~ ${protected} ]]; then
            fail
        fi
    done
fi

exit 0
