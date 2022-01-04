#!/usr/local/bin/node

/**
 * @file pan-wp-update-users.js
 * 
 * Remove all users with email addresses from a given domain from a WordPress site,
 * and transfer their content to a new admin user.
 * 
 * Usage: ./scripts/node/wp-update-users.js hotdogs-corp.live steve.hotdogs@gmail.com myagency.biz
 *
 * Arguments:
 *   siteEnv (str) a Pantheon site name and environment
 *   newAdminEmail (str) email address for the new site admin user
 *   offboardDomain (str) email domain for users to remove from WordPress
 */

const { execSync } = require('child_process')
const readline = require('readline')

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const siteEnv = process.argv[2] !== undefined ? process.argv[2] : process.env['SITE_ENV']
const newAdminEmail = process.argv[3] !== undefined ? process.argv[3] : process.env['ADMIN_EMAIL']
const offboardDomain = process.argv[4] !== undefined ? process.argv[4] : process.env['OFFBOARD_DOMAIN']

if (!newAdminEmail || !siteEnv) {
    console.log('To run this script, pass the site name and target environment, new admin email, and offboarding domain as arguments, like this:')
    console.log('./update-wp-users.js hotdogs-corp.live steve.hotdogs@gmail.com myagency.biz')
    process.exit(1)
}

// Create a new WordPress account for our new admin.
// Stash the new user ID for for use when reassigning content from offboarded users.
console.log(`Creating an admin account for ${newAdminEmail}...`)
let adminUID = execSync(`terminus wp ${siteEnv}  -- user create ${newAdminEmail} ${newAdminEmail} --role=administrator --porcelain`)

// Update the site admin email.
console.log('Updating the site admin email...')
execSync(`terminus wp ${siteEnv}  -- option update admin_email ${newAdminEmail}`)

// Find all the accounts with an $offboardDomain email address.
console.log(`Looking for ${offboardDomain} user accounts...`)

// Use NodeJS to have PHP run a MySQL query, why not #yolo
let query = `SELECT user_email FROM wp_users WHERE user_email LIKE "%${offboardDomain}%";`
let offboard_emails = execSync(`echo '${query}' | terminus wp ${siteEnv} -- db query --skip-column-names`).toString()

console.log("Found these users to offboard: \n")
console.log(offboard_emails);

// Confirm account deletions.
rl.question(`Delete these WordPress accounts, and reassign content to ${newAdminEmail}? [y/n] `, (input) => {
    if (input === 'y' || input === 'yes') {
        // Delete accounts and reassign content to our new admin.
        offboard_emails = convertNewlinesSpaces(offboard_emails)
        execSync(`terminus wp ${siteEnv}  -- user delete ${offboard_emails} --reassign=${adminUID}`)
    }
    else if (input === 'n' || input === 'no') {
        console.log("Skipping account removal.")
    }
    console.log("User updates complete! 🌮")
    rl.close();
});

/**
 * Re-format database query output into a useable string.
 * 
 * @param {string} emails 
 *   User emails separated with newlines.
 * @returns {string}
 *   User emails separated with a space.
 */
const convertNewlinesSpaces = (emails) => {
    return emails.replace(/\r?\n|\r/g, " ").trim();
}