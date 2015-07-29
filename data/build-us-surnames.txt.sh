#!/bin/bash
#
# Parses names, from
# http://www2.census.gov/topics/genealogy/2000surnames/names.zip.
# Writes a list of unique, newline-separated surnames to us-surnames.txt.gz

DIR="$(dirname "$0")"

# * Unzip names.zip
# * Take only column 1
# * Nix the header
# * Normalize: punctuation->space
# * Normalize: trim strings
# * Normalize: lowercase
# * Sort and unique-ize
unzip -p "$DIR"/names.zip app_c.csv \
  | cut -d, -f1 \
  | tail -n+1 \
  | perl -pe 's/[- \(\)!`"\/&{}~]+/ /g' \
  | perl -pe 's/^ +| +$//g' \
  | perl -ne 'binmode(STDIN, ":utf8"); binmode(STDOUT, ":utf8"); print lc' \
  | LC_ALL=C sort -u \
  > "$DIR"/us-surnames.txt

zopfli "$DIR"/us-surnames.txt
