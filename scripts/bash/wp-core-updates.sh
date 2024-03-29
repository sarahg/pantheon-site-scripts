#!/bin/bash

# Runs a WordPress core update for a list of sites in a text file.
#
# Usage: ./wp-core-updates.sh

set -eou pipefail

echo "Running core updates..."

for SITENAME in ${SITES//,/ }; do
  echo "Site: $SITENAME"
  terminus upstream:updates:apply "$SITENAME"
done
