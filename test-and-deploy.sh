#!/bin/bash

set -eou pipefail

#TAG="maintenance"
TAG="testing"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --field=name --tag=${TAG} --filter="framework=wordpress" -- $ORG_UUID)

# @TODO Break out the deploy/QA steps to a different script.

# Prompt for a quick manual QA.
# @TODO VRT instead! Or Autopilot!
# @TODO Only prompt on sites we actually updated something.
echo "[notice] Go check the Test sites: "
while read -r SITENAME; do
    echo -e "- https://test-${SITENAME}.pantheonsite.io"
done <<< "$SITES"

# @TODO Deploy to Live
#terminus env:deploy --sync-content --note="Plugin updates." -- "${SITENAME}".test