#!/bin/bash
#
# Parses allCountries.zip, from http://download.geonames.org/export/dump/, and
# writes a list of unique, newline-separated place names to
# geonames-cities

DIR="$(dirname "$0")"

# * Unzip allCountries.zip
# * Grep for populated places ('P', from http://www.geonames.org/export/codes.html)
# * Filter for column 15 (population) > 10,000
# * Take out column 2 ("names") and 4 ("alternatenames", comma-separated)
# * Split by each name/alternatename onto its own line
# * Filter out numbers
# * Filter out URLs
# * Normalize: punctuation->space
# * Normalize: trim strings (broken by previous normalization)
# * Normalize: lowercase
# * Normalize: strip all but first 5 words
# * Sort and filter out duplicate place names (this is the only slow part)
unzip -p "$DIR"/allCountries.zip \
  | grep -P '\tP\t' \
  | awk 'BEGIN { FS = "\t" } { if ($15 >= 10000) { print $2; print $4 } }' \
  | perl -pe 's/,/\n/g' \
  | perl -ne 'print unless /^[-\d\s\.]+$/' \
  | perl -ne 'print unless /^https?:/' \
  | perl -pe 's/[- \(\)!`"\/&{}~]+/ /g' \
  | perl -pe 's/^ +| +$//g' \
  | perl -ne 'binmode(STDIN, ":utf8"); binmode(STDOUT, ":utf8"); print lc' \
  | cut -d' ' -f1-5 \
  | LC_ALL=C sort -u --parallel=2 --buffer-size=40% \
  > "$DIR"/geonames-cities.txt

zopfli "$DIR"/geonames-cities.txt
