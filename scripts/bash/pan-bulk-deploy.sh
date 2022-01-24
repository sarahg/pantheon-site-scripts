#!/bin/bash

# Deploy pending code changes for a list of sites.
#
# This creates a database backup, and deploys
# Test to Live. Includes update-db/update.php, and
# cache clears for both the CMS and Redis.
#
# Usage: ./pan-bulk-deploy.sh SITES ENV

set -eou pipefail

DEPLOYED=()

for SITENAME in ${SITES//,/ }
do
    # Skip this site if there isn't anything to deploy.
    # @todo this check actually deploys things :(
    # rework with a check on terminus env:code-log instead
    # DEPLOY_STATUS=$(terminus env:deploy "${SITENAME}"."${ENV}" --simulate 2>&1)
    # EMPTY_RESP="nothing to deploy"
    # if [[ "$DEPLOY_STATUS" == *"$EMPTY_RESP"* ]]; then
        # echo "No updates to deploy for $SITENAME."
        # continue
    # fi

    # Backup and deploy.
    echo "Deploying $SITENAME..."
    terminus backup:create "${SITENAME}"."${ENV}" --element=db
    terminus env:deploy "${SITENAME}"."${ENV}" --note="Maintenance updates."

    # CMS-specific database operations.
    FRAMEWORK="$(terminus site:info "${SITENAME}" --field=Framework)"
    if [ "$FRAMEWORK" == "wordpress" ]; then
        terminus wp "${SITENAME}"."${ENV}" -- core update-db < /dev/null
    fi

    if [ "$FRAMEWORK" == "drupal" ]; then
        terminus drush "${SITENAME}"."${ENV}" -- updb < /dev/null
    fi

    # Clear the framework cache.
    terminus env:clear-cache "${SITENAME}"."${ENV}"

    # Flush Redis if it's enabled.
    REDIS_CMD=$(terminus connection:info "${SITENAME}"."${ENV}" --field="redis_command")
    if [ -n "${REDIS_CMD}" ]; then
        echo "Clearing Redis..."
        eval "$REDIS_CMD --no-auth-warning" flushall
    fi

    DEPLOYED+=("$SITENAME")
done

# @todo DEPLOYED is not what we think it is, only returned first value
if (( ${#DEPLOYED[@]} )); then
    echo "[notice] Code deployed: "
    for SITENAME in ${DEPLOYED//,/ }
    do
        echo -e "- https://${ENV}-${SITENAME}.pantheonsite.io"
    done
fi