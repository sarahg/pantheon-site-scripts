#!/bin/bash

# Collects PHP and nginx logs from a single site.
#
# Usage: ./pan-collect-logs.sh SITENAME

SITENAME=${1}

function site-id {
  terminus site:info "$1" --field=ID
}

# @todo: Add an option to only pull PHP logs?

if [ ! -d "logs" ]; then
  mkdir logs
fi
if [ ! -d "logs/${SITENAME}" ]; then
  mkdir logs/"${SITENAME}"
fi

SITE_UUID="$(site-id "${SITENAME}")"
ENV=live
for appserver in $(dig +short -4 appserver.$ENV."$SITE_UUID".drush.in); do
  rsync -rlvz --size-only --ipv4 --progress -e "ssh -p 2222" "$ENV.$SITE_UUID@$appserver:logs" "logs/${SITENAME}/appserver_$appserver"
done
