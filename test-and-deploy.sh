#!/bin/bash

set -eou pipefail

#TAG="maintenance"
TAG="testing"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --field=name --tag=${TAG} --filter="framework=wordpress" -- $ORG_UUID)

# @TODO Incorporate AutoPilot?

# Deploy to Live
while read -r SITENAME; do
    terminus env:deploy --note="Code updates." -- "${SITENAME}".live
    # @todo add a cache clear?
done <<< "$SITES"