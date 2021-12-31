# Pantheon Site Scripts

Sarah's toolkit for maintenance work on sites running on [Pantheon](https://pantheon.io).

## Usage

Check the code comment at the top of each script for specific usage directions, but most of the bash scripts utilize an environment variable, `$SITES`, which is a list of Pantheon site names to run the script on.

```
export SITES=updog,hotdogcorp
./wp-core-updates
```

To run these in a container, you can use the [Pantheon-Docker-Build-Tools-CI](https://github.com/pantheon-systems/docker-build-tools-ci) image. 

To run these locally, you'll need [Terminus](https://pantheon.io/docs/terminus/), [jq](https://stedolan.github.io/jq/download/), and [Shellcheck](https://github.com/koalaman/shellcheck) for testing the bash scripts. To run a load test with Goose, you'll also need [Rust](https://www.rust-lang.org/tools/install).

## Testing

### Bash scripts
Run `./test.sh` to run Shellcheck over everything in the `scripts/bash` directory. Shellcheck also runs on CircleCI when code is pushed to GitHub.

### Run a load test
Work in progress!

From the `loadtest` directory:
`cargo run --release -- --host https://example.com --report-file=report.html`

This is a very basic example that just hits the homepage and is copied from the Goose "[Getting Started](https://book.goose.rs/getting-started/overview.html)" doc. Eventually it'd be neat to pair this with output from `scripts/bash/wp-extract-yoast-sitemap.sh` to crawl the full site.