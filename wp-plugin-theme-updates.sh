#!/bin/bash

set -eou pipefail

#TAG="maintenance"
TAG="testing"

# @todo use an env var for the org
ORG_UUID="1439ef14-9fed-428e-8943-902e36c763a9"
SITES=$(terminus org:site:list --field=name --tag=${TAG} --filter="framework=wordpress" -- $ORG_UUID)

# Number of seconds to pause between applying the update and trying to commit.
# Pantheon takes a few seconds to register the code diffs as committable.
OSD_SLEEP_INTERVAL=5

# Loop through all sites on the list.
while read -r SITENAME; do
    echo "Site: $SITENAME"
    # Retrieve plugin list using Launchcheck. This allows us to differentiate security/non-security releases.
    # @TODO use .value.vulnerable to note security updates. 
    # It has escaped HTML in it, which F's everything up as-is.
    # There's likely a method to replace that value with something nicer for JSON -- we just need a boolean.
    PLUGINS="$(terminus wp "${SITENAME}".dev -- launchcheck plugins --format=json < /dev/null | jq -c '.plugins.alerts | to_entries[] | select (.value.needs_update == "1") | [.value.slug, .value.installed, .value.available]')"
    # Get theme updates.
    THEMES="$(terminus wp "${SITENAME}".dev -- theme update --all --format=json --dry-run < /dev/null | jq -r '.[].name')"

    if [ -n "$PLUGINS" ] || [ -n "$THEMES" ]
    then

        terminus connection:set "${SITENAME}".dev sftp

        # Update plugins and commit changes.
        if [ -n "$PLUGINS" ]
        then
            echo "$SITENAME has updates. Applying updates..."
            for PLUGIN in $PLUGINS; do
                SLUG="$(echo "$PLUGIN" | jq -r '.[0]')"
                INSTALLED="$(echo "$PLUGIN" | jq -r '.[1]')"
                AVAILABLE="$(echo "$PLUGIN" | jq -r '.[2]')"

                terminus wp "${SITENAME}".dev -- plugin update "${SLUG}" --format=summary < /dev/null
                MESSAGE="Update $SLUG ($INSTALLED => $AVAILABLE)."
                sleep $OSD_SLEEP_INTERVAL
                terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"
            done
        fi

        # Update themes and commit changes.
        if [ -n "$THEMES" ]
        then
            for THEME in $THEMES; do
                terminus wp "${SITENAME}".dev -- theme update "${THEME}" < /dev/null
                MESSAGE="Update $THEME theme." # @todo show version like we do for plugins? is this actually useful?
                sleep $OSD_SLEEP_INTERVAL
                terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"
            done
        fi

        # Deploy to Test env.
        # @todo build a full update list, write it to a file, and use it for the note
        terminus env:deploy --sync-content --note="Code updates." -- "${SITENAME}".test
        terminus env:clear-cache "${SITENAME}".test

    fi
done <<< "$SITES"

# Updates are done, go check them out.
# @todo handling for cases where there are no updates.
echo "[notice] Go check the Test sites: "
while read -r SITENAME; do
    echo -e "- https://test-${SITENAME}.pantheonsite.io"
done <<< "$SITES"