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
  # The input is an Array of unigram tokens. To form ngrams, we'll concatenate
  # them with spaces. (We'll also normalize by setting them lowercase.)
  #
  # We must stay memory-efficient: assume there is a super-high number of
  # unique ngrams in the array of unigrams (which, therefore, may be
  # super-long).
  #
  # The return value may contain duplicates.
  findTokensFromUnigrams: (unigrams) ->
    unigramsBuffer = new Buffer(unigrams.join(' ').toLowerCase(), 'utf-8') # Encode as binary

    startPositions = new Array(0) # a (fake) circular buffer, max size maxNgramLength

    ret = []

    testNgrams = (endPosition) =>
      for startPosition in startPositions
        if @test(unigramsBuffer, startPosition, endPosition)
          s = unigramsBuffer.toString('utf-8', startPosition, endPosition)
          ret.push(s)
      null

    for byte, pos in unigramsBuffer
      if byte == 0x20 # Space
        testNgrams(pos)
        startPositions.shift() if startPositions.length == @maxNgramSize
        startPositions.push(pos + 1)

    while startPositions.length > 1
      testNgrams(unigramsBuffer.length)
      startPositions.shift()

    ret
