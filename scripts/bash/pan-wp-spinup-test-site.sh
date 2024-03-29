#!/bin/bash

# Creates a throwaway Pantheon site to use for testing our scripts.
#
# This is not really suitable for automated testing in its current state;
# this is mostly intended to speed up manual testing.
#
# Usage: ./pan-wp-spinup-test-site.sh

# Pantheon site name.
RANDOM_ID=$(echo /dev/urandom | base64 | tr -dc '0-9a-zA-Z' | head -c5)
SITE="sg-wp-test-${RANDOM_ID}"

# Initialize the site and install WordPress.
terminus site:create --org="${PANTHEON_ORG_ID}" -- "$SITE" "$SITE" wordpress
terminus wp "$SITE".dev -- core install --title="Just Testing" --url="https://dev-${SITE}.pantheonsite.io" --admin_user="test_admin" --admin_email="test@example.com" --admin_password="${RANDOM_ID}"

# Add some mock users.
terminus wp "$SITE".dev -- user create test_editor test1@example.com --role=editor
terminus wp "$SITE".dev -- user create test_admin2 test2@example.com --role=administrator
terminus wp "$SITE".dev -- user create test_author test3@example.com --role=author

# Add some fake content.
terminus wp "$SITE".dev -- post generate --count=10 --post_type=page --post_author=test_editor
terminus wp "$SITE".dev -- post generate --count=10 --post_type=post --post_author=test_admin2

# Push a fake secrets file.
terminus rsync scripts/node/tests/mock-secrets.json "${SITE}".dev:files/private

# Add a multidev.
terminus env:create "$SITE".dev devclone
