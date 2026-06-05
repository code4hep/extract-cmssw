#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <base-ref> <head-ref> [notes-file]"
    echo ""
    echo "List PRs merged in CMSSW into <head-ref> since <base-ref>."
    echo ""
    echo "Arguments:"
    echo "  base-ref    The starting ref (e.g. origin/main or a tag/commit)"
    echo "  head-ref    The ending ref (e.g. a branch name or HEAD)"
    echo "  notes-file  Optional file to append PR titles and links to"
    exit 0
}

if [[ $# -lt 2 ]] || [[ $# -gt 3 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

BASE_REF="$1"
HEAD_REF="$2"
NOTES_FILE="${3:-}"
CMSSW_REPO="https://github.com/cms-sw/cmssw"

MERGED_PRS=$(git log --merges --pretty="%s" "${BASE_REF}".."${HEAD_REF}" | sed -n 's/.*Merge pull request #\([0-9]*\).*/\1/p' | tac)
if command -v gh &> /dev/null; then
    GH_AVAILABLE=true
else
    GH_AVAILABLE=false
    echo "Note: GitHub CLI ('gh') not found in PATH, PR titles will be omitted."
    echo "You can run the 'list-merges.sh ${BASE_REF} ${HEAD_REF}' script in a repository with 'gh' installed to get the PR titles included."
fi
for PR in $MERGED_PRS; do
    if $GH_AVAILABLE; then
        TITLE=$(gh pr view ${CMSSW_REPO}/pull/${PR} --json title --template "{{.title}}")
        LINE="- ${TITLE} (${CMSSW_REPO}/pull/${PR})"
    else
        LINE="- ${CMSSW_REPO}/pull/${PR}"
    fi
    echo "${LINE}"
    if [[ -n "${NOTES_FILE}" ]]; then
        echo "${LINE}" >> "${NOTES_FILE}"
    fi
done
