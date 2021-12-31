#!/bin/bash

# Build a text file containing all URLs from a site's Yoast-generated sitemap.
#
# Adapted from https://jclsn.medium.com/extract-yoast-sitemap-xml-to-url-list-e65ed18d2188
#
# Usage:    ./wp-extract-yoast-sitemap.sh DOMAIN OUTPUT
# Example:  ./wp-extract-yoast-sitemap.sh https://example.com/sitemap_index.xml output.txt

if [[ $# -eq 0 ]] ; then
    echo "run extract_yoast_sitemap.sh https://example.com/sitemap_index.xml output.txt"
    exit 0
fi

echo "# URL list" > $2
main_url=$(curl -s $1 | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
for i in $main_url
do
    urls=$(curl -s $i | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
    for site_url in $urls
    do
        echo "$site_url"
        echo "$site_url" >> $2
    done
done