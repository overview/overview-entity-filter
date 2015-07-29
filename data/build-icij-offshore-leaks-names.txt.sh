#!/bin/bash
#
# Parses csv.zip, from http://offshoreleaks.icij.org/about/download, and
# writes a list of unique, single-word tokens to
# icij-offshore-leaks-names.txt.gz

DIR="$(dirname "$0")"

# * Unzip csv.zip
# * Nix the column headers
# * Take out column 4 ('searchField_'), semicolon-delimited
# * Remove quotation marks
# * Split by space/punctuation, each token onto its own line
# * Normalize: lowercase
# * Sort and filter out duplicate tokens
unzip -p "$DIR"/csv.zip 'csv 2014 01 23/nodesNW.csv' \
  | tail -n+1 \
  | cut -d';' -f4 \
  | cut -d'"' -f2 \
  | perl -pe 's/[-\s#,\.*:+$\(\)!`\/&{}~]+/\n/g' \
  | perl -ne 'binmode(STDIN, ":utf8"); binmode(STDOUT, ":utf8"); print lc' \
  | LC_ALL=C sort -u --parallel=2 --buffer-size=40% \
  > "$DIR"/icij-offshore-leaks-names.txt

zopfli "$DIR"/icij-offshore-leaks-names.txt
