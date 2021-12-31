#!/bin/bash

# Deploy pending code changes to Live for a list of sites.
#
# This creates a database backup, and deploys
# Test to Live. Includes update-db/update.php, and
# cache clears for both the CMS and Redis.
#
# Usage: ./pan-bulk-deploy.sh SITES

set -eou pipefail

DEPLOYED=()

for SITENAME in ${SITES//,/ }
do
    # Skip this site if there isn't anything to deploy.
    DEPLOY_STATUS=$(terminus env:deploy ${SITENAME}.live 2>&1)
    EMPTY_RESP="nothing to deploy"

    if [[ "$DEPLOY_STATUS" == *"$EMPTY_RESP"* ]]; then
        echo "No updates to deploy for $SITENAME."
        continue
    fi

    # Backup and deploy.
    echo "Deploying $SITENAME..."
    terminus backup:create "${SITENAME}".live --element=db
    terminus env:deploy "${SITENAME}".live --note="Maintenance updates."

    # CMS-specific database operations.
    FRAMEWORK="$(terminus site:info "${SITENAME}" --field=Framework)"
    if [ "$FRAMEWORK" == "wordpress" ]; then
        terminus wp "${SITENAME}".live -- core update-db < /dev/null
    fi

    if [ "$FRAMEWORK" == "drupal" ]; then
        terminus drush "${SITENAME}".live -- updb < /dev/null
    fi

    # Clear the framework cache.
    terminus env:clear-cache "${SITENAME}".live

    # Flush Redis if it's enabled.
    # @todo reuse REDIS_CMD output
    REDIS_CMD=$(terminus connection:info ${SITENAME}.live --field="redis_command")
    if [ -n "${REDIS_CMD}" ]; then
        echo "Clearing Redis..."
        eval "$REDIS_CMD" flushall
    fi

    DEPLOYED+=($SITENAME)
done

if (( ${#DEPLOYED[@]} )); then
    echo "[notice] Code deployed: "
    for SITENAME in ${DEPLOYED//,/ }
    do
        echo -e "- https://live-${SITENAME}.pantheonsite.io"
    done
fi