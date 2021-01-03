#!/bin/bash

set -eou pipefail

# Include all of the functions that we need.
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/functions/pantheon-script-colours"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --field=name --tag=maintenance --filter="framework=wordpress" -- $ORG_UUID)

# Update plugins and deploy to Test.
while read -r SITENAME; do
    echo "Site: $SITENAME"

    PLUGINS="$(terminus wp "${SITENAME}".dev -- launchcheck plugins --format=json < /dev/null | jq -c '.plugins.alerts | keys[]')"

    for PLUGIN in $PLUGINS; do
        echo $PLUGIN
    done


    HAS_UPDATES="true"
    if [ -z "$HAS_UPDATES" ]
    then
        echo "$SITENAME has no updates."
    else
        echo "$SITENAME has updates"
        #  terminus connection:set "${SITENAME}".dev sftp
        # terminus wp "${SITENAME}".dev -- plugin update --all)
    fi

    # @todo commit each update in a separate commit

    # @todo Use Advomatic script for deploys
    # https://github.com/Advomatic/pantheon-tools/blob/main/pantheon-quick-deploy

done <<< "$SITES"

echo "[notice] Go check the Test sites"
# Post link to each test site, https://sitename-test.pantheonsite.io

# Prompt to deploy to Live, or cancel.
# If cancel, print commands to deploy each site individually to Live.