# code4hep scripts for extracting components from CMSSW

These scripts require the `git-filter-repo` package to be installed.

These scripts optionally make use of the GitHub CLI ('gh').

## Common

The `list-merges.sh` script lists the PRs merged in a given range of commits. It takes two arguments, the base and head
refs, and prints out the PR numbers that were merged in that range. If the GitHub CLI (`gh`) is available in `$PATH`, it
also prints out the titles of those PRs.

## Stitched

The `extract-stitched.sh` script extracts the Stitched packages from
CMSSW. It also stitches the CMSSW's CVS and git histories together in
away that produces nicer history than what was possible to do in
CMSSW. The script starts by cloning the CMSSW git repository, and
results in
- an updated `cmssw_master` branch, and
- a `CMSSW_<YYYY>_<MM>_<DD>_<hash>` tag, where `<YYYY>`, `<MM>`, and
  `<DD>` are the date when the script was run, and the `hash` the the
  commit ID of CMSSW's `master` branch at the time of the extraction

The script prints out, and stores in `ReleaseNotes.md`, the PRs that
were merged in CMSSW touching the Stitched packages by using the `list-merges.sh` script.

The `cmssw_master` and `CMSSW_<YYYY>_<MM>_<DD>_<hash>` should then be pushed to the Stitched repository.
