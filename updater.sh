#/usr/bin/bash

# Run the core update script.
core-updates

# Run the plugin/theme update script.
wp-plugin-theme-updates

# Run the deploy script.
test-and-deploy

# Build the report. @todo
# Post to Slack. @todo