#!/usr/bin/env python3
#
# Parses all googlebooks-eng-all-1gram-20120701-*.gz, from
# http://storage.googleapis.com/books/ngrams/books/datasetsv2.html, and writes
# the top 50,000 uncapitalized words (by frequency, total) to
# googlebooks-words.en.txt.gz.

import glob
import gzip
import heapq
import os.path

Pattern = 'googlebooks-eng-all-1gram-20120701-*.gz'
NTokens = 50000

class WordHeap:
    def __init__(self):
        self.tokens = []
        self.counts = {} # dict from token to count

    def feed_line(self, line):
        # ignore non-lowercase tokens: they're probably proper nouns
        if not 'a' <= line[0] <= 'z': return

        # Line format: ngram TAB year TAB match_count TAB volume_count NEWLINE
        tab1 = line.find('\t')
        tab2 = tab1 + 5 # The year is always four characters long
        tab3 = line.find('\t', tab2 + 1)

        word_end = line.find('_', 0, tab1)
        if word_end == -1: word_end = tab1

        token = line[0:word_end]
        match_count = int(line[tab2 + 1:tab3])

        if token in self.counts:
            self.counts[token] += match_count
        else:
            self.tokens.append(token)
            self.counts[token] = match_count

    def get_top_words(self):
        print('Sorting %d tokens...' % len(self.tokens))
        self.tokens.sort(key=lambda token: -self.counts[token])
        return [ (token + ' ' + str(self.counts[token])) for token in self.tokens[0:NTokens] ]

def find_input_paths():
    return sorted(glob.glob(os.path.join(os.path.dirname(__file__), Pattern)))

def main():
    word_heap = WordHeap()

    for path in find_input_paths():
        print('Processing %s...' % path)
        with gzip.open(path, mode='rt', encoding='utf-8') as f:
            for line in f:
                word_heap.feed_line(line)

    words = word_heap.get_top_words()
    words.sort()

    print('Writing...')
    with gzip.open('googlebooks-words.en.txt.gz', mode='wt', encoding='utf-8') as f:
        f.write('\n'.join(words))

if __name__ == '__main__':
    main()
