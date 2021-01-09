# Pantheon Janitor Toolkit

> janitor [ **jan**-i-ter ]
> *noun*
> a person employed in an apartment house, office building, school, etc., to clean the public areas, remove garbage, and do minor repairs; caretaker.

Sarah's toolkit for caretaking of [Pantheon](https://pantheon.io) sites.

## Run updates

@TODO DOCUMENT THIS

## Install

### Requirements
* Sarah's [Terminus fork](https://github.com/sarahg/terminus), checked out to the `env-info-diffstat` branch (@TODO Write a test and make a PR to actual Terminus with this, or rethink steps that utilize the `uncommitted_changes` field in env:info)
* jq: https://stedolan.github.io/jq/
* Make sure this repo is in your `$PATH`:

`export PATH="$PATH:$HOME/projects/pantheon-janitor-toolkit"`

You typically add this lines to ~/.bash_profile or ~/.zshrc.