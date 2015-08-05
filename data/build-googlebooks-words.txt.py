#!/usr/bin/env python3
#
# Parses all googlebooks-eng-all-1gram-20120701-*.gz, from
# http://storage.googleapis.com/books/ngrams/books/datasetsv2.html, and writes
# the top 50,000 uncapitalized words (by frequency, total) to
# googlebooks-words.en.txt.gz.

import glob
import gzip
import os.path

NTokens = 50000

tokens = []
token_counts = {} # dict from token to count

def process_file(f):
    for line in f:
        if line == '': continue
        if not line[0].islower(): continue # Assume lowercase means proper noun

        # Line format: ngram TAB year TAB match_count TAB volume_count NEWLINE
        tab1 = line.find('\t')
        tab2 = tab1 + 5 # The year is always four characters long
        tab3 = line.find('\t', tab2 + 1)

        word_end = line.find('_', 0, tab1)
        if word_end == -1: word_end = tab1

        token = line[0:word_end]
        match_count = int(line[tab2 + 1:tab3])

        if token in token_counts:
            token_counts[token] += match_count
        else:
            tokens.append(token)
            token_counts[token] = match_count

def get_top_words():
    print('Sorting %d tokens...' % len(tokens))
    tokens.sort(key=lambda token: -token_counts[token])
    return [ (token + ' ' + str(token_counts[token])) for token in tokens[0:NTokens] ]

def find_input_paths(lang):
    files = glob.glob(os.path.join(os.path.dirname(__file__), 'googlebooks-%s-all-1gram-20120701-*.gz' % lang))
    files.sort()
    return files

def main(lang):
    for path in find_input_paths(lang):
        print('Processing %s...' % path)
        with gzip.open(path, mode='rt', encoding='utf-8') as f: process_file(f)

    words = get_top_words()
    words.sort()

    print('Writing...')
    with gzip.open('googlebooks-words.%s.txt.gz' % lang, mode='wt', encoding='utf-8') as f:
        f.write('\n'.join(words))

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print("Usage: %s [lang]" % sys.argv[0], file=sys.stderr)
        print("", file=sys.stderr)
        print("Where [lang] is eng, rus, et cetera", file=sys.stderr)
        sys.exit(1)
    lang = sys.argv[1]

    main(lang)
