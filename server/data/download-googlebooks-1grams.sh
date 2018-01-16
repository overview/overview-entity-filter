#!/bin/sh

lang="$1"

if [ -z "$lang" ]; then
  >&2 echo "Usage: $0 [lang]"
  >&2 echo
  >&2 echo "Where [lang] is eng, rus, spa, et cetera."
  exit 1
fi

for x in a b c d e f g h i j k l m n o other p q r s t u v w x y z; do
  wget "http://storage.googleapis.com/books/ngrams/books/googlebooks-$lang-all-1gram-20120701-${x}.gz"
done
