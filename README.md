# Pantheon Site Scripts

Sarah's toolkit for maintenance work on sites running on [Pantheon](https://pantheon.io).

## Usage

Check the code comment at the top of each script for specific usage directions, but most of these take an argument of SITES (Pantheon site names) and run an action over all of those specified sites.

```
export SITES=updog,hotdogcorp
./wp-core-updates $SITES
```

To run these in a Docker container, you can use the [Pantheon-Docker-Build-Tools-CI](https://github.com/pantheon-systems/docker-build-tools-ci) image (someday I'll add a Dockerfile here). To run these locally, you'll need [Terminus](https://pantheon.io/docs/terminus/), [Terminus Mass Update Plugin](https://github.com/pantheon-systems/terminus-mass-update), [jq](https://stedolan.github.io/jq/download/), and [Shellcheck](https://github.com/koalaman/shellcheck).

Check out the .circleci folder for examples of how to use these on a CI service and run them automatically on a schedule.

## Testing

Run `./test.sh` to run Shellcheck over everything in the scripts directory. (Eventually I'd like to run this as a GitHub Action, but currently some are throwing errors, so let's start with that!).
