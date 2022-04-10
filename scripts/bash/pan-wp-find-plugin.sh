#!/bin/bash

# This script checks all paid sites in a Pantheon org for a given WordPress plugin.
# This may be useful in the event of an urgent security release.
#
# Usage:
# ./pan-wp-find-plugin.sh your-org-id plugin-slug

PANTHEON_ORG_UUID=${1}
FIND_PLUGIN=${2}

# Get WordPress sites with a paid site plan.
PAID_WP_SITES="$(terminus org:site:list "$PANTHEON_ORG_UUID" --filter="plan_name!=sandbox&&framework=wordpress" --format=list --field=Name)"

# Check each site to see if it has the given plugin.
while read -r SITENAME; do

  PLUGINS="$(terminus wp "${SITENAME}".dev -- plugin list --field=name </dev/null)"

  for PLUGIN in $PLUGINS; do
    if [[ "$PLUGIN" == "$FIND_PLUGIN" ]]; then

      echo "🚨 $SITENAME is running $FIND_PLUGIN"

      # Un-comment the following if you want to actually run the plugin update right meow:

      # terminus connection:set "${SITENAME}".dev sftp
      # terminus wp "${SITENAME}".dev -- plugin update "${FIND_PLUGIN}" --format=summary < /dev/null
      # terminus env:commit "${SITENAME}".dev --message="Updated ${FIND_PLUGIN}"

      # Un-comment this part if you want to push to Test:

      # terminus env:deploy "${SITENAME}".test
      # terminus env:clear-cache "${SITENAME}".test
      # terminus wp "${SITENAME}".test -- core update-db < /dev/null

      # And un-comment this if you want to make a database backup and push to Live:

      # terminus backup:create "${SITENAME}".live --element=db
      # terminus env:deploy "${SITENAME}".live
      # terminus env:clear-cache "${SITENAME}".live
      # terminus wp "${SITENAME}".live -- core update-db < /dev/null

    fi
  done

done <<<"$PAID_WP_SITES"
