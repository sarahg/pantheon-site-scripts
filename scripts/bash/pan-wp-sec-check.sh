#!/bin/bash

# This script checks all paid sites in a Pantheon org for security updates.
# 
# Usage:
# ./pan-wp-sec-check.sh your-org-id

set -eou pipefail

PANTHEON_ORG_UUID=${1}


# Get WordPress sites with a paid site plan.
PAID_WP_SITES="$(terminus org:site:list "$PANTHEON_ORG_UUID" --filter="plan_name!=sandbox&&framework=wordpress" --format=list --field=Name)"

# Check each site to see if it has pending security updates.
while read -r SITENAME; do

    PLUGINS="$(terminus wp "${SITENAME}".live -- launchcheck plugins --format=json < /dev/null | jq -c '.plugins.alerts | to_entries[] | select (.value.vulnerable != "None") | .key')"

    for PLUGIN_SLUG in $PLUGINS; do

        echo "🚨 $SITENAME needs to update $PLUGIN_SLUG"
            
        # Un-comment the following if you want to actually run the plugin update right meow:

        # terminus connection:set "${SITENAME}".dev sftp
        # terminus wp "${SITENAME}".dev -- plugin update "${PLUGIN_SLUG}" --format=summary < /dev/null
        # terminus env:commit "${SITENAME}".dev --message="Updated ${PLUGIN_SLUG}"

        # Un-comment this part if you want to push to Test:

        # terminus env:deploy "${SITENAME}".test
        # terminus env:clear-cache "${SITENAME}".test
        # terminus wp "${SITENAME}".test -- core update-db < /dev/null

        # And un-comment this if you want to go yolo-mode and push to Live:

        # terminus backup:create "${SITENAME}".live --element=db
        # terminus env:deploy "${SITENAME}".live
        # terminus env:clear-cache "${SITENAME}".live
        # terminus wp "${SITENAME}".live -- core update-db < /dev/null
            
    done

done <<< "$PAID_WP_SITES"