#!/bin/bash

set -eou pipefail

# Include all of the functions that we need.
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/functions/pantheon-script-colours"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --format=list --tag=maintenance --filter="framework=wordpress" -- $ORG_UUID)

# Make sure the dev env is clean.
# Requires Sarah's Terminus fork to add the "uncommitted_changes" field.
while read -r SITE_UUID; do
    ENV_INFO="$(terminus env:info --fields=uncommitted_changes,connection_mode --format=json "${SITE_UUID}".dev)"
    DIRTY=$(jq .'uncommitted_changes' <<< "${ENV_INFO}" )
    CONNECTION_MODE=$(jq -r .'connection_mode' <<< "${ENV_INFO}" )

    if [[ "$DIRTY" == "true" ]]; then
        echo -e "${INVERSE}[warning]${NOINVERSE} Site $SITE_UUID has uncommitted code on Dev. Remediate before proceededing."
    
    elif [[ "$CONNECTION_MODE" == "sftp" ]]; then
        # SFTP mode without uncommitted code is OK, 
        # but we still need to flip it to Git to proceed.
        echo "${INVERSE}[notice]${NOINVERSE} Changing connection setting for ${SITE_UUID}"
        terminus connection:set "${SITE_UUID}".dev git
    fi

done <<< "$SITES"

echo "${TIP}Running core updates..."
terminus site:mass-update:apply <<< "$SITES"