# Pantheon Site Scripts

Sarah's toolkit for maintenance work on sites running on [Pantheon](https://pantheon.io).

## Usage

Check the code comment at the top of each script for specific usage directions, but most of these utilize an environment variable, `$SITES`, which is a list of Pantheon site names to run the script on.

```
export SITES=updog,hotdogcorp
./wp-core-updates
```

To run these in a container, you can use the [Pantheon-Docker-Build-Tools-CI](https://github.com/pantheon-systems/docker-build-tools-ci) image. 

To run these locally, you'll need [Terminus](https://pantheon.io/docs/terminus/), [jq](https://stedolan.github.io/jq/download/), and [Shellcheck](https://github.com/koalaman/shellcheck) for testing.