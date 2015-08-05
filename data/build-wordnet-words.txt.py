#!/usr/bin/env python3
#
# Parses wn3.1.dict.tar.gz, from
# http://wordnet.princeton.edu/wordnet/download/current-version/, and writes a
# list of unique, newline-separated potential English words to
# wordnet-words.txt.gz.

import gzip
import io
import tarfile

# Not really WordNet, but the user definitely means to include these...
#
# WordNet only contains nouns, verbs, adjectives and adverbs. That leaves
# pronouns, prepositions and conjunctions. Thankfully, that's a finite set....
#
# Listed here: http://www.d.umn.edu/~tpederse/Group01/WordNet/words.txt
def get_stopwords():
    return [ 'a', 'aboard', 'about', 'above', 'across', 'after', 'against', 'all', 'along', 'alongside', 'although', 'amid', 'amidst', 'among', 'amongst', 'an', 'and', 'another', 'anti', 'any', 'anybody', 'anyone', 'anything', 'around', 'as', 'astride', 'at', 'aught', 'bar', 'barring', 'because', 'before', 'behind', 'below', 'beneath', 'beside', 'besides', 'between', 'beyond', 'both', 'but', 'by', 'circa', 'concerning', 'considering', 'despite', 'down', 'during', 'each', 'either', 'enough', 'everybody', 'everyone', 'except', 'excepting', 'excluding', 'few', 'fewer', 'following', 'for', 'from', 'he', 'her', 'hers', 'herself', 'him', 'himself', 'his', 'hisself', 'I', 'idem', 'if', 'ilk', 'in', 'including', 'inside', 'into', 'it', 'its', 'itself', 'like', 'many', 'me', 'mine', 'minus', 'more', 'most', 'myself', 'naught', 'near', 'neither', 'nobody', 'none', 'nor', 'nothing', 'notwithstanding', 'of', 'off', 'on', 'oneself', 'onto', 'opposite', 'or', 'other', 'otherwise', 'our', 'ourself', 'ourselves', 'outside', 'over', 'own', 'past', 'pending', 'per', 'plus', 'regarding', 'round', 'save', 'self', 'several', 'she', 'since', 'so', 'some', 'somebody', 'someone', 'something', 'somewhat', 'such', 'suchlike', 'sundry', 'than', 'that', 'the', 'thee', 'theirs', 'them', 'themselves', 'there', 'they', 'thine', 'this', 'thou', 'though', 'through', 'throughout', 'thyself', 'till', 'to', 'tother', 'toward', 'towards', 'twain', 'under', 'underneath', 'unless', 'unlike', 'until', 'up', 'upon', 'us', 'various', 'versus', 'via', 'vis-a-vis', 'we', 'what', 'whatall', 'whatever', 'whatsoever', 'when', 'whereas', 'wherewith', 'wherewithal', 'which', 'whichever', 'whichsoever', 'while', 'who', 'whoever', 'whom', 'whomever', 'whomso', 'whomsoever', 'whose', 'whosoever', 'with', 'within', 'without', 'worth', 'ye', 'yet', 'yon', 'yonder', 'you', 'you-all', 'yours', 'yourself', 'yourselves' ]

# Finds possible permutations of word, given it is a:
#
# * n: NOUN
# * a: ADJ
# * v: VERB
#
# We reverse the logic described at
# http://wordnet.princeton.edu/wordnet/man/morphy.7WN.html. This produces more
# words than there actually are in English, but it's hard to find a dictionary
# that actually stores every valid permutation of every word, and we're better
# off overshooting than undershooting.
#
# We handle irregular permutations elsewhere.
def permute(word, type_code):
    ret = [ word ]
    if type_code == 'n':
        ret.append(word + 's')
        if word.endswith('s'): ret.append(word + 'es')
        if word.endswith('x'): ret.append(word + 'es')
        if word.endswith('z'): ret.append(word + 'es')
        if word.endswith('ch'): ret.append(word + 'es')
        if word.endswith('sh'): ret.append(word + 'es')
        if word.endswith('man'): ret.append(word[0:-3] + 'men')
        if word.endswith('y'): ret.append(word[0:-1] + 'ies')
    if type_code == 'v':
        ret.append(word + 's')
        ret.append(word + 'es')
        ret.append(word + 'd')
        ret.append(word + 'ed')
        ret.append(word + 'ing')
        if word.endswith('e'): ret.append(word[0:-1] + 'ing')
        if word.endswith('y'): ret.append(word[0:-1] + 'ies')
    if type_code == 'a':
        ret.append(word + 'er')
        ret.append(word + 'est')
        if word.endswith('e'):
            ret.append(word + 'r')
            ret.append(word + 'st')

    return ret

# Finds all words from an index file-like object.
#
# Each word in the index will be permuted using permute().
def get_words(f, type_code):
    ret = []

    with io.TextIOWrapper(f, encoding='utf-8') as text:
        for line in text.readlines():
            idx = line.find(' ')
            if idx < 1: continue # comment, or end-of-file
            word = line[0:idx]
            # Skip words that our tokenizer will never produce
            if '.' in word or '_' in word or '-' in word: continue
            ret.extend(permute(word, type_code))

    return ret

# Finds all nouns from index and data file-like objects.
#
# Each word in the index will be permuted using permute().
#
# This is different from get_words() because it excludes proper nouns. To
# determine whether a noun is a proper noun:
#
# 1. Find a word in index_f. Set `proper_noun=True`.
# 2. Look up each synset of the word in `data_f`. If the first letter of the
#    synset is *not* capitalized, set `proper_noun=False` and break
def get_nouns(index_f, data_f):
    ret = []

    data = data_f.read()

    with io.TextIOWrapper(index_f, encoding='utf-8') as text:
        for line in text.readlines():
            if line.find(' ') < 1: continue # comment, or end-of-file
            parts = line.split()

            lemma = parts[0]

            # Skip words that our tokenizer will never produce
            if '.' in lemma or '_' in lemma or '-' in lemma: continue

            n_synsets = int(parts[2])

            for synset_offset_str in parts[-n_synsets:]:
                synset_offset = int(synset_offset_str)
                first_letter_offset = synset_offset + 17
                first_letter = data[first_letter_offset:first_letter_offset+1] # a 1-byte bytes
                if b'a' <= first_letter <= b'z':
                    ret.extend(permute(lemma, 'n'))
                    break

    return ret


# Finds all non-standardly-derived words from a file-like object.
def get_exceptions(f):
    ret = []

    with io.TextIOWrapper(f, encoding='utf-8') as text:
        for line in text.readlines():
            idx = line.find(' ')
            if idx < 1: continue # comment, or end-of-file
            ret.append(line[0:idx])

    return ret

# Finds all words from a WordNet file
def extract_all_words(path):
    ret = []

    with tarfile.open(path, mode='r:gz', encoding='utf-8') as tar:
        with tar.extractfile('dict/index.adj') as f: ret.extend(get_words(f, 'a'))
        with tar.extractfile('dict/index.adv') as f: ret.extend(get_words(f, 'r'))
        with tar.extractfile('dict/index.noun') as f:
            with tar.extractfile('dict/data.noun') as df:
                ret.extend(get_nouns(f, df))
        with tar.extractfile('dict/index.verb') as f: ret.extend(get_words(f, 'v'))
        with tar.extractfile('dict/adj.exc') as f: ret.extend(get_exceptions(f))
        with tar.extractfile('dict/adv.exc') as f: ret.extend(get_exceptions(f))
        with tar.extractfile('dict/noun.exc') as f: ret.extend(get_exceptions(f))
        with tar.extractfile('dict/verb.exc') as f: ret.extend(get_exceptions(f))

    return ret

def main():
    words = extract_all_words('wn3.1.dict.tar.gz')
    words.extend(get_stopwords())
    words = list(set(words)) # Remove duplicates
    words.sort()

    with gzip.open('wordnet-words.txt.gz', mode='wt', encoding='utf-8', newline='\n') as out:
        out.write('\n'.join(words))

if __name__ == '__main__':
    main()
