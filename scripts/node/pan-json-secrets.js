#!/usr/local/bin/node

/**
 * @file pan-json-secrets.js
 * 
 * Fetch secrets.json files from each env of a given Pantheon site,
 * and prompt the user to remove secret keys and re-upload them.
 * 
 * This script is useful if you're transferring ownership of a site
 * and need to quickly remove tokens used for things like Quicksilver
 * Slack notifications.
 * 
 * Usage: ./scripts/node/pan-json-secrets.js mycoolsite
 * Arguments:
 *   site (str) a Pantheon site name
 */

const { execSync } = require('child_process')
const readline = require('readline')

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Take the site name as an argument (or, optionally, pass it in as an environment variable).
const site = process.argv[2] !== undefined ? process.argv[2] : process.env['SITE']

// Download secrets.json from Live.
console.log("Downloading secrets.json from the Live environment...")
execSync(`terminus rsync ${site}.live:/files/private/secrets.json .`)

// @todo 
// The script crashes hard here if secrets.json doesn't exist
// and rsync returns an error.
// That's fine since this becomes a no-op at that point anyways,
// but it'd be nice to print a message and exit nicely.

// Prompt the user to review and update the secrets file.
console.log("\nPlease update secrets.json to remove secret keys.")
console.log("When you're ready to upload the updated file, enter y below, or enter n to quit.")

// Confirm account deletions.
rl.question("Upload secrets.json? [y/n] ", (input) => {
    if (input === 'y' || input === 'yes') {

        // Fetch a list of multidevs and split this into an array of multidev names.
        console.log("Loading environment list...")
        let multidevs = execSync(`terminus multidev:list ${site} --field=Name`).toString().trim().split("\n")

        // Don't forget Dev/Test/Live.
        let allEnvs = multidevs.concat(['dev', 'test', 'live']);

        // Rsync secrets.json up to every environment.
        console.log("Uploading secrets.json to all environments...\n")
        allEnvs.forEach(env => {
            execSync(`terminus rsync secrets.json ${site}.${env}:files/private`)
        });

        console.log("\nUploads complete! Thank you for protecting our secret keys. Have a burrito 🌯");
    }
    if (input === 'n' || input === 'no') {
        process.exit()
    }
    rl.close();
});
