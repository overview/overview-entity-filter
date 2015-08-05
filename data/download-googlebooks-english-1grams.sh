#!/bin/sh

for x in a b c d e f g h i j k l m n o other p q r s t u v w x y z; do
  wget "http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-1gram-20120701-${x}.gz"
done
