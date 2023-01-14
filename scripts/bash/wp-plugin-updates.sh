#!/bin/bash

# Apply plugin updates for a list of sites,
# and deploy them to the Test environment.
#
# Usage: ./wp-plugin-updates.sh SITES

set -eou pipefail

UPDATED=()

# Loop through all sites on the list.
for SITENAME in ${SITES//,/ }; do
  echo "Site: $SITENAME"
  # Check for plugin updates.
  PLUGINS="$(terminus wp "${SITENAME}".dev -- plugin update --all --format=json --dry-run </dev/null | jq -c '.[]')"

  if [ -n "$PLUGINS" ]; then
    echo "$SITENAME has updates."
    terminus connection:set "${SITENAME}".dev git

    # Clone the site to a temporary directory.
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t)

    GIT_URL="$(terminus connection:info "${SITENAME}".dev --field=git_url)"
    git clone "${GIT_URL}" "${TMP_DIR}"/"${SITENAME}"
    cd "${TMP_DIR}"/"${SITENAME}"

    for PLUGIN in $PLUGINS; do
      SLUG="$(echo "$PLUGIN" | jq -r '.name')"
      INSTALLED="$(echo "$PLUGIN" | jq -r '.version')"
      AVAILABLE="$(echo "$PLUGIN" | jq -r '.update_version')"

      rm -rf wp-content/plugins/"${SLUG}"
      curl -O https://downloads.wordpress.org/plugin/"${SLUG}".zip
      unzip "$SLUG".zip -d wp-content/plugins/
      rm "$SLUG".zip

      MESSAGE="Update $SLUG ($INSTALLED => $AVAILABLE)."
      git add . && git commit -am "${MESSAGE}"

      UPDATED+=("${SITENAME}")
    done

    # Push to Pantheon dev.
    git push origin master

    # Apply DB updates on dev all at once.
    terminus wp "${SITENAME}".dev -- core update-db </dev/null

    # Deploy to Test env.
    terminus env:deploy --sync-content --note="Plugin updates." -- "${SITENAME}".test
    terminus wp "${SITENAME}".test -- core update-db </dev/null
    terminus env:clear-cache "${SITENAME}".test
  fi
done

# Updates are done, go check them out.
echo "[notice] Go check the Test sites: "
for SITENAME in ${UPDATED//,/ }; do
  echo -e "- https://test-${SITENAME}.pantheonsite.io"
done
