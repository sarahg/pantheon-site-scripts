#!/bin/bash

# Deploy WordPress upates to a list of sites.
#
# This creates a database backup, and deploys
# Test to Live. Includes update-db and a cache clear.
#
# Usage: ./pan-bulk-deploy.sh SITES

set -eou pipefail

# @todo skip if there isn't anything to deploy
for SITENAME in ${SITES//,/ }
do
    echo "Deploying $SITENAME..."
    terminus backup:create "${SITENAME}".live --element=db
    terminus env:deploy --note="Maintenance updates." -- "${SITENAME}".live
    terminus wp "${SITENAME}".live -- core update-db < /dev/null
    terminus env:clear-cache "${SITENAME}".live
done

# @todo handling for cases where there are no updates.
echo "[notice] Go check the Live sites: "
for SITENAME in ${SITES//,/ }
do
    # @todo curl the homepage + login page and verify HTTP/200
    echo -e "- https://live-${SITENAME}.pantheonsite.io"
done
