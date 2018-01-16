#!/bin/bash
#
# Parses http://svn.tartarus.org/snowball/trunk/website/algorithms/english/stop.txt
# and writes it to stop.en.txt.

DIR="$(dirname "$0")"
URL="svn://svn.tartarus.org/snowball/trunk/website/algorithms/english/stop.txt"

# Grab the contents
# Nix comments that start with `|`, or all whitespace
# Sort and filter out duplicates
# Nix the empty string that's left
svn cat svn://svn.tartarus.org/snowball/trunk/website/algorithms/english/stop.txt \
  | perl -pe 's/^\s*//' \
  | perl -pe 's/\s*(\|.*)?\n/\n/' \
  | LC_ALL=c sort -u \
  | tail -n+2 \
  > "$DIR"/stop.en.txt
