#!/bin/bash

# Apply plugin updates for a list of sites,
# and deploy them to the Test environment.
#
# Usage: ./wp-plugin-updates.sh SITES

set -eou pipefail

# Number of seconds to pause between applying the update and trying to commit.
# Pantheon takes a few seconds to register the code diffs as committable.
OSD_SLEEP_INTERVAL=7

# Loop through all sites on the list.
for SITENAME in ${SITES//,/ }
do
    echo "Site: $SITENAME"
    # Check for plugin updates.
    PLUGINS="$(terminus wp "${SITENAME}".dev -- plugin update --all --format=json --dry-run < /dev/null | jq -c '.[]')"

    if [ -n "$PLUGINS" ]
    then

        terminus connection:set "${SITENAME}".dev sftp
        # @todo flag staged/uncommitted changes (e.g, leftovers from a script fail)

        echo "$SITENAME has updates. Applying updates..."
        for PLUGIN in $PLUGINS; do
            SLUG="$(echo "$PLUGIN" | jq -r '.name')"
            INSTALLED="$(echo "$PLUGIN" | jq -r '.version')"
            AVAILABLE="$(echo "$PLUGIN" | jq -r '.update_version')"

            terminus wp "${SITENAME}".dev -- plugin update "${SLUG}" --format=summary < /dev/null
            MESSAGE="Update $SLUG ($INSTALLED => $AVAILABLE)."
            sleep $OSD_SLEEP_INTERVAL
            terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"
        done

        # Apply DB updates on dev all at once.
        terminus wp "${SITENAME}".dev -- core update-db < /dev/null

        # Deploy to Test env.
        # @todo build a full update list and use it for the note
        terminus env:deploy --sync-content --note="Maintenance updates." -- "${SITENAME}".test
        terminus wp "${SITENAME}".test -- core update-db < /dev/null
        terminus env:clear-cache "${SITENAME}".test

        # Put the dev site back in Git mode for added security.
        terminus connection:set "${SITENAME}".dev git 

    fi
done

# Updates are done, go check them out.
# @todo handling for cases where there are no updates.
echo "[notice] Go check the Test sites: "
for SITENAME in ${SITES//,/ }
do
    echo -e "- https://test-${SITENAME}.pantheonsite.io"
done