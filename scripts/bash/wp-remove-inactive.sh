#!/bin/bash

# Clean up inactive plugins and themes.
#
# Usage: ./wp-remove-inactive.sh SITE

set -eou pipefail

SITENAME=${1}

# We want to keep the latest core theme, just in case we need to troubleshoot theme issues.
LATEST_CORE_THEME="twentytwentyone"

# Number of seconds to pause between applying the update and trying to commit.
# Pantheon takes a few seconds to register the code diffs as committable.
OSD_SLEEP_INTERVAL=7

echo "Site: $SITENAME"

# Check for inactive plugins.
PLUGINS="$(terminus wp "${SITENAME}".live -- plugin list --status=inactive --format=json </dev/null | jq -c '.[]')"

if [ -n "$PLUGINS" ]; then

  terminus connection:set "${SITENAME}".dev sftp
  # @todo flag staged/uncommitted changes (e.g, leftovers from a script fail)

  echo "$SITENAME has inactive plugins. Removing..."
  for PLUGIN in $PLUGINS; do
    SLUG="$(echo "$PLUGIN" | jq -r '.name')"

    terminus wp "${SITENAME}".dev -- plugin delete "${SLUG}" </dev/null
    MESSAGE="Remove inactive plugin: ${SLUG}."
    sleep $OSD_SLEEP_INTERVAL
    terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"
  done
fi

# Check for inactive themes.
THEMES="$(terminus wp "${SITENAME}".live -- theme list --status=inactive --format=json </dev/null | jq -r '.[] | .name | select(contains('\""${LATEST_CORE_THEME}"\"') | not)')"

if [ -n "$THEMES" ]; then

  terminus connection:set "${SITENAME}".dev sftp
  # @todo flag staged/uncommitted changes (e.g, leftovers from a script fail)

  echo "$SITENAME has inactive themes. Removing..."
  for THEME in $THEMES; do
    echo "Removing ${THEME}"
    terminus wp "${SITENAME}".dev -- theme delete "${THEME}" </dev/null
    MESSAGE="Remove inactive theme: ${THEME}."
    sleep $OSD_SLEEP_INTERVAL
    terminus env:commit "${SITENAME}".dev --message="${MESSAGE}"
  done
fi

# Deploy to Test env.
terminus env:deploy --sync-content --note="Removing inactive themes." -- "${SITENAME}".test
terminus env:clear-cache "${SITENAME}".test

# Put the dev site back in Git mode for added security.
terminus connection:set "${SITENAME}".dev git
