# Pantheon Site Scripts

Sarah's toolkit for maintenance work on sites running on [Pantheon](https://pantheon.io).

## Run site updates

Run these scripts sequentially:

1) core-updates
2) wp-plugin-theme-updates
3) test-and-deploy
4) site-report-card

## Install

### Requirements
* Sarah's [Terminus fork](https://github.com/sarahg/terminus), checked out to the `env-info-diffstat` branch (@TODO Write a test and make a PR to actual Terminus with this, or rethink steps that utilize the `uncommitted_changes` field in env:info)
* jq: https://stedolan.github.io/jq/
* Make sure this repo is in your `$PATH`:

`export PATH="$PATH:$HOME/projects/pantheon-site-scripts"`

You typically add this lines to ~/.bash_profile or ~/.zshrc.