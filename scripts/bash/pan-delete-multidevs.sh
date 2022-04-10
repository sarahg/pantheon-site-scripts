#!/bin/bash

# Delete all multidevs for a Pantheon site.
#
# Usage: ./pan-delete-multidevs.sh SITE

set -eou pipefail

site=${1}
system_envs=("dev" "test" "live")
all_envs="$(terminus env:list "$site" --field=ID)"

echo "Deleting multidevs for ${site}..."

for env in ${all_envs}; do
  if [[ ! " ${system_envs[*]} " =~ ${env} ]]; then
    terminus multidev:delete "${site}"."${env}" --yes
  fi
done
