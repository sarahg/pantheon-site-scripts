#!/bin/bash

# Run a backup on each environment of a given list of sites.
#
# Usage: ./pan-sandbox-backups.sh SITES

set -eou pipefail

for site in ${SITES//,/ }
do
    echo "Creating backups for ${site}..."
    ENVS="$(terminus env:list "$site" --filter='initialized=1' --field=ID)"
    for ENV in ${ENVS}
    do
      terminus -n backup:create "${site}"."${ENV}"
    done
done