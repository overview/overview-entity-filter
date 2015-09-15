TokenSet = require('./TokenSet')

Suffixes = [
  'AG'
  'B.V'
  'Corp'
  'Corporation'
  'CORP'
  'CORPORATION'
  'GmbH'
  'GMBH'
  'Inc'
  'INC'
  'Incorporated'
  'INCORPORATED'
  'LLC'
  'Ltd'
  'LTD'
  'Limited'
  'LIMITED'
  'Pty'
  'PTY'
  'S.A'
]

SuffixesSet = {}
(SuffixesSet[suffix] = null) for suffix in Suffixes

# A token set built by searching backwards after finding company suffixes.
#
# For instance, take the sentence: "I like Acme Corp and Acme Corp likes me."
# This logic will move forward until it finds "Corp", then it will check that
# "Acme" is capitalized, then it will see that "like" is not capitalized; as a
# result, it will output "Acme Corp".
module.exports = class SuffixedCompaniesTokenSet extends TokenSet
  constructor: (maxNgramSize) ->
    super(maxNgramSize)

  test: (token) -> false

  findTokensFromUnigrams: (unigrams) ->
    unigrams = unigrams.split(' ') # Still capitalized
    ret = []

    i = 1
    tokenEnd = null # The suffix: find this first
    tokenStart = null # The first capitalized word before it: backtrack to find this
    while i < unigrams.length
      if unigrams[i] of SuffixesSet
        tokenEnd = i
        tokenStart = i

        while true
          break if tokenStart <= 0 # No more words to check
          break if tokenStart - 1 + @maxNgramSize <= tokenEnd # Too long
          word = unigrams[tokenStart - 1]
          break if word of SuffixesSet # We're reading a list of companies, and this is the end of a previous one
          char = word[0]
          break if char.toUpperCase() != char # We've reached a non-capitalized word
          tokenStart -= 1

        if tokenStart < tokenEnd
          ret.push(unigrams[tokenStart .. tokenEnd].join(' '))

      i += 1

    ret
