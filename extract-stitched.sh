#!/bin/bash

set -euo pipefail

PATHS="DataFormats/Common
       DataFormats/Provenance
       DataFormats/StdDictionaries
       DataFormats/TestObjects
       DataFormats/WrappedStdDictionaries
       FWCore/AbstractServices
       FWCore/Common
       FWCore/Concurrency
       FWCore/Framework
       FWCore/Integration
       FWCore/MessageLogger
       FWCore/MessageService
       FWCore/Modules
       FWCore/ParameterSet
       FWCore/ParameterSetReader
       FWCore/PluginManager
       FWCore/PythonFramework
       FWCore/PythonParameterSet
       FWCore/PythonUtilities
       FWCore/Reflection
       FWCore/ServiceRegistry
       FWCore/Services
       FWCore/SharedMemory
       FWCore/SOA
       FWCore/Sources
       FWCore/TestModules
       FWCore/TestProcessor
       FWCore/Utilities
       FWCore/Version
       .clang-format
       .clang-tidy
       .gitignore
       LICENSE
       NOTICE
       README"
PATHS_ARGS=""
for P in $PATHS; do
    PATHS_ARGS="${PATHS_ARGS} --path ${P}"
done

# "Configuration"
EXTRACT_BRANCH="cmssw_master"
CMSSW_REPO="https://github.com/cms-sw/cmssw"
STITCHED_REPO="git@github.com:code4hep/stitched-alpha2.git"

# In the original CMSSW
# 83a929aead1 is the last commit from CVS. It was merged in CMSSW_6_2_0
# 214ab7313d6 (CMSSW_7_0_0_pre0) is the first commit of the clean git history

# In the extraction after the filter-repo to the packages
# 74b274f4b is the last commit from CVS. It mwas merged in CMSSW_6_2_0
#  this commit can be found with "git log CMSSW_6_2_0" It has title
#  "This commit was manufactured by cvs2git to create tag 'CMSSW_6_2_0'",
#  and it's parent is "Improve exception message for unscheduled circular dependences"
# 6260c5bde (CMSSW_7_0_0_pre0) is the first commit of the clean git history
#
# Note that the commit hashes in the Stitched extraction will change if the $PATHS above is changed

echo "$(date) Starting"
echo
echo "Cloning CMSSW"
git clone ${CMSSW_REPO}.git
cd cmssw

CMSSW_HEAD_ID=$(git rev-parse --short master)
echo
echo "CMSSW master HEAD is ${CMSSW_HEAD_ID}"

# Filtering the Stitched packages first and then doing the CVS-git history stitching is much, much faster than
echo
echo "Filtering the Stitched packages"
git filter-repo ${PATHS_ARGS} --force
echo
echo "Stitching the CVS history to git history"
git replace 6260c5bde 74b274f4b
git filter-repo --proceed --force

# Create the CMSSW extraction branch
git branch ${EXTRACT_BRANCH}
# Create a tag for the CMSSW extraction point
DATE=$(date +%Y_%m_%d)
EXTRACT_TAG="CMSSW_${DATE}_${CMSSW_HEAD_ID}"
git tag ${EXTRACT_TAG}

echo
echo "$(date) Finished"

echo "Preparing for rebase, executing the following"
STITCHED_ORIGIN="stitched-origin"

echo "git remote add ${STITCHED_ORIGIN} ${STITCHED_REPO}"
git remote add ${STITCHED_ORIGIN} ${STITCHED_REPO}

echo "git fetch ${STITCHED_ORIGIN}"
git fetch ${STITCHED_ORIGIN}

LATEST_MAIN=$(git remote show ${STITCHED_ORIGIN} | grep main_ | grep -v HEAD | awk '{print $1}' | sort -u)
NEW_MAIN="main_${DATE}"
echo "git branch ${NEW_MAIN} ${STITCHED_ORIGIN}/${LATEST_MAIN}"
git branch ${NEW_MAIN} ${STITCHED_ORIGIN}/${LATEST_MAIN}

NOTES_FILE="ReleaseNotes.md"
echo
echo "Following PRs were merged in the CMSSW since the last extraction (from oldest to newest). Include these in the Stitched release notes (the list is saved in ${NOTES_FILE})."
MERGED_PRS=$(git log --merges --pretty="%s" ${STITCHED_ORIGIN}/${EXTRACT_BRANCH}..${EXTRACT_BRANCH} | sed -n 's/.*Merge pull request #\([0-9]*\).*/\1/p' | tac)
if command -v gh &> /dev/null; then
    GH_AVAILABLE=true
else
    GH_AVAILABLE=false
    echo "Note: GitHub CLI ('gh') not found in PATH, PR titles will be omitted from ${NOTES_FILE}"
fi
for PR in $MERGED_PRS; do
    echo "- ${CMSSW_REPO}/pull/${PR}"
    if $GH_AVAILABLE; then
        TITLE=$(gh pr view ${CMSSW_REPO}/pull/${PR} --json title --template "{{.title}}")
        echo "- ${TITLE} (${CMSSW_REPO}/pull/${PR}) " >> ${NOTES_FILE}
    else
        echo "- ${CMSSW_REPO}/pull/${PR}" >> ${NOTES_FILE}
    fi
done

echo
echo "Next you need to rebase the ${NEW_MAIN} branch, and push everything back to the Stitched repository"
echo "cd cmssw"
echo "git rebase ${EXTRACT_BRANCH} ${NEW_MAIN}"
echo "git push ${STITCHED_ORIGIN} ${EXTRACT_BRANCH} ${EXTRACT_TAG} ${NEW_MAIN}"
