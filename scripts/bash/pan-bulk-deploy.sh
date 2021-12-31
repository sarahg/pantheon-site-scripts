#!/bin/bash

# Deploy pending code changes to Live for a list of sites.
#
# This creates a database backup, and deploys
# Test to Live. Includes update-db/update.php, and
# cache clears for both the CMS and Redis.
#
# Usage: ./pan-bulk-deploy.sh SITES

set -eou pipefail

for SITENAME in ${SITES//,/ }
do
    FRAMEWORK="$(terminus site:info "${SITENAME}" --field=Framework)"

    echo "Deploying $SITENAME..."
    terminus backup:create "${SITENAME}".live --element=db
    terminus env:deploy --note="Maintenance updates." -- "${SITENAME}".live

    if [ "$FRAMEWORK" == "wordpress" ]; then
        terminus wp "${SITENAME}".live -- core update-db < /dev/null
    fi

    if [ "$FRAMEWORK" == "drupal" ]; then
        terminus drush "${SITENAME}".live -- updb < /dev/null
    fi

    REDIS_CMD=$(terminus connection:info ${SITENAME}.live --field="redis_command")
    if [ -n "${REDIS_CMD}" ]; then
        echo "Clearing Redis..."
        $(terminus connection:info ${SITENAME}.live --field="redis_command") flushall
    fi

    terminus env:clear-cache "${SITENAME}".live
done

echo "[notice] Code deployed: "
for SITENAME in ${SITES//,/ }
do
    echo -e "- https://live-${SITENAME}.pantheonsite.io"
done