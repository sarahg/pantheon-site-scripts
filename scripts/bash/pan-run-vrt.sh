#!/bin/bash

# Runs a visual regression test, comparing a multidev
# against the live site. Requires node and backstopJS.
#
# Install backstopjs:
# npm install -g backstopjs
#
# You'll also need to have a backstop-config file located at
# backstop-config/$SITE-backstop.json
#
# Docs: How to create a Backstop config file:
# https://github.com/garris/BackstopJS#initializing-your-project
#
# Usage: ./pan-run-vrt.sh SITENAME

set -eou pipefail

SITENAME=${1}
CONFIG_FILE="backstop-config/${SITENAME}-backstop.json"

# Create a multidev of Live.
terminus multidev:create "${SITENAME}".live vrt

# Build a reference file and run VRT.
backstop reference --configPath="${CONFIG_FILE}"
backstop test --configPath="${CONFIG_FILE}"

# Remove the multidev.
terminus multidev:delete "${SITENAME}".vrt
