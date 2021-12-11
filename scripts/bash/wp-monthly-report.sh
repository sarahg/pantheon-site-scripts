#!/bin/bash

# Creates a JSON object of site health info and
# maintenance records. This can be used with a front-end app
# to create a client-friendly report of the work we've done on the site
# this month.
#
# Currently this writes to the local filesystem, so it's not suitable for CI usage.
#
# Usage: ./wp-monthly-report.sh 2021-01

set -eou pipefail

start=$(date +%s)

MONTH=${1} # e.g, 2021-01 # @todo throw a nice friendly error when i forget this
# or just default to last month

# Copy the report template into a new dir for this month.
# @todo move this to another project
create_file() {
    SITENAME=${1}
    REPORT_DIR=${2}
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir "${REPORT_DIR}"
    fi
    REPORT_FILE="${REPORT_DIR}/index.html"
    cp reports/template.html "${REPORT_FILE}"
}

# Pull down list of Pingdom checks. @TODO
# curl -s -H "Authorization: Bearer ${PINGDOM_API_TOKEN_PERSONAL}" \
#    "https://api.pingdom.com/api/3.1/checks" > ${CHECKS_JSON}

# Loop through all sites on the list.
while IFS='' read -r SITENAME || [ -n "${SITENAME}" ]; do
    
    # Copy the report template.
    REPORT_DIR=reports/output/$SITENAME-$MONTH
    create_file "${SITENAME}" "${REPORT_DIR}"

    DOMAINS="$(terminus domain:list --format=json "${SITENAME}".live)"
    PRIMARY_DOMAIN="$(echo "${DOMAINS}" | jq -r '.[] | select(.primary==true) | .id')"
    if [ -z "$PRIMARY_DOMAIN" ]; then
        PRIMARY_DOMAIN="live-$SITENAME.pantheonsite.io"
    fi

    # Get code updates from this month.
    # @todo these timestamps are in UTC. 
    # Might be wrong for commits at the end of the last day of the month.
    # To get this right we'd need to work with a local copy of the repo and 
    # utilize git config --global log.date local https://stackoverflow.com/a/7651782/1940172
    COMMITS="$(terminus env:code-log --fields=datetime,message --format=json "${SITENAME}".live | jq -c '.[] | select(.datetime | contains('\""${MONTH}"\"'))')"
    COMMITS_JSON=$(echo "${COMMITS}" | jq -s '.')

    # Health checks.
    # @todo pull from Pingdom
    # Currently we just tweak this manually if it's not 100
    UPTIME="100%"

    # Backups
    BACKUPS="$(terminus workflow:list "${SITENAME}" --format=json | jq -c '.[] | select(.workflow | contains("Automated backup for the \"live\""))')"
    BACKUPS_ENABLED="Yes"
    if [ -z "$BACKUPS" ]; then
        BACKUPS_ENABLED="No"
    fi
    GOOD_BACKUPS="$(echo "${BACKUPS}" | jq -c '. | select(.status=="succeeded")')"
    LATEST_BACKUP=$(echo "${GOOD_BACKUPS}" | jq -s '.[0]')

    # Hackerz
    EXPLOITS="$(terminus wp "${SITENAME}".live launchcheck -- secure --format=json < /dev/null | jq '.exploited.result')"
    PANTHEON_METRICS="$(terminus env:metrics "${SITENAME}".live --period=month --datapoints=2 --format=json)"

    # Write all our findings to a JSON file for use by the report template.
    if [ ! -d "$REPORT_DIR/json" ]; then
        mkdir "${REPORT_DIR}"/json
    fi
    JSON_STRING=$( jq -n \
                  --arg site "$SITENAME" \
                  --arg month "$MONTH" \
                  --argjson updates "$COMMITS_JSON" \
                  --arg domain "$PRIMARY_DOMAIN" \
                  --arg uptime "$UPTIME" \
                  --arg backups_on "$BACKUPS_ENABLED" \
                  --argjson backups_latest "$LATEST_BACKUP" \
                  --argjson exploits "$EXPLOITS" \
                  --argjson metrics "$PANTHEON_METRICS" \
                  '[{site:$site, month,$month, updates: $updates, domain:$domain, uptime:$uptime, backups_on:$backups_on, backups_latest:$backups_latest, exploits:$exploits, metrics:$metrics}]' )
    echo "${JSON_STRING}" > "${REPORT_DIR}"/json/report.json

done < "$SITELIST"

end=$(date +%s)
runtime=$((end-start))
echo $runtime