# Represents a set of tokens.
#
# Usage:
#
#   tokenSet = findMyTokenSetSomehow()
#   tokenSet.test('foo') # true or false
#   tokenSet.test('bar') # true or false
#   tokenSet.findTokensFromUnigrams([ 'foo', 'bar', 'baz' ], 2)
#     # ^^ will test 'foo', 'bar', 'baz', 'foo bar', 'bar baz' and return an
#     # Array with whichever tokens match.
module.exports = class TokenSet
  # Builds a TokenSet. Called by child classes.
  #
  # The maxNgramSize is a property of the token set: one token set may only
  # contain unigrams, so there's no point in testing anything wider.
  constructor: (@maxNgramSize) ->

  # Returns true iff the token is in the set.
  test: (token) -> throw new Error('not implemented')

  # Returns an Array of ngram tokens that appear in the set.
  #
  # The input is a space-separated String of unigram tokens. They won't
  # necessarily be uppercase/lowercase, because the token finder might care
  # about case.
  #
  # We must stay memory-efficient: assume there are ~100k unique unigrams tops,
  # but make no assumptions about the number of ngrams.
  #
  # The return value may contain duplicates.
  findTokensFromUnigrams: (unigrams) ->
    startPositions = new Array(0) # a (fake) circular buffer, max size maxNgramLength

    ret = []

    testNgrams = (endPosition) =>
      for startPosition in startPositions
        s = unigrams.slice(startPosition, endPosition)
        ret.push(s) if @test(s)
      null

    for char, pos in unigrams
      if char == ' ' # Space
        testNgrams(pos)
        startPositions.shift() if startPositions.length == @maxNgramSize
        startPositions.push(pos + 1)

    while startPositions.length > 1
      testNgrams(unigrams.length)
      startPositions.shift()

    ret
