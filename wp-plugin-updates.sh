#!/bin/bash

set -eou pipefail

#TAG="maintenance"
TAG="testing"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --field=name --tag=${TAG} --filter="framework=wordpress" -- $ORG_UUID)

# Loop through all sites on the list.
while read -r SITENAME; do
    echo "Site: $SITENAME"

    # Retrieve plugin list.
    # @TODO it'd be nice to also grab .value.vulnerable so we could flag these, 
    # but it has escaped HTML in it, which F's everything up.
    # There's likely a method to replace that value with something nicer for JSON -- we just need a boolean.
    PLUGINS="$(terminus wp "${SITENAME}".dev -- launchcheck plugins --format=json < /dev/null | jq -c '.plugins.alerts | to_entries[] | select (.value.needs_update == "1") | [.value.slug, .value.installed, .value.available]')"

    # Apply updates and commit each one.
    if [ -n "$PLUGINS" ]
    then
        echo "$SITENAME has updates. Applying updates..."
        terminus connection:set "${SITENAME}".dev sftp

        for PLUGIN in $PLUGINS; do

            SLUG="$(echo "$PLUGIN" | jq -r '.[0]')"
            INSTALLED="$(echo "$PLUGIN" | jq -r '.[1]')"
            AVAILABLE="$(echo "$PLUGIN" | jq -r '.[2]')"

            # Update plugin and commit the change.
            terminus wp "${SITENAME}".dev -- plugin update "${SLUG}" --format=summary < /dev/null
            MESSAGE="Update $SLUG ($INSTALLED => $AVAILABLE)."
            sleep 4
            terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"

        done

        # Deploy to Test env.
        terminus env:deploy --sync-content --note="Plugin updates." -- "${SITENAME}".test
        terminus env:clear-cache "${SITENAME}".test

    else
        echo "$SITENAME has no plugin updates."
    fi

done <<< "$SITES"

# @TODO Break out the deploy/QA steps to a different script.

# Prompt for a quick manual QA.
# @TODO VRT instead! Or Autopilot!
# @TODO Only prompt on sites we actually updated something.
echo "[notice] Go check the Test sites: "
while read -r SITENAME; do
    echo -e "- https://test-${SITENAME}.pantheonsite.io"
done <<< "$SITES"