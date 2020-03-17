/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Represents a set of tokens.
//
// Usage:
//
//   tokenSet = findMyTokenSetSomehow()
//   tokenSet.test('foo') # true or false
//   tokenSet.test('bar') # true or false
//   tokenSet.findTokensFromUnigrams([ 'foo', 'bar', 'baz' ], 2)
//     # ^^ will test 'foo', 'bar', 'baz', 'foo bar', 'bar baz' and return an
//     # Array with whichever tokens match.
let TokenSet;
module.exports = (TokenSet = class TokenSet {
  // Builds a TokenSet. Called by child classes.
  //
  // The maxNgramSize is a property of the token set: one token set may only
  // contain unigrams, so there's no point in testing anything wider.
  constructor(maxNgramSize) {
    this.maxNgramSize = maxNgramSize;
  }

  // Returns true iff the token is in the set.
  test(token) { throw new Error('not implemented'); }

  // Returns an Array of ngram tokens that appear in the set.
  //
  // The input is a space-separated String of unigram tokens. They won't
  // necessarily be uppercase/lowercase, because the token finder might care
  // about case.
  //
  // We must stay memory-efficient: assume there are ~100k unique unigrams tops,
  // but make no assumptions about the number of ngrams.
  //
  // The return value may contain duplicates.
  findTokensFromUnigrams(unigrams) {
    const startPositions = new Array(0); // a (fake) circular buffer, max size maxNgramLength

    const ret = [];

    const testNgrams = endPosition => {
      for (let startPosition of Array.from(startPositions)) {
        const s = unigrams.slice(startPosition, endPosition);
        if (this.test(s)) { ret.push(s); }
      }
      return null;
    };

    for (let pos = 0; pos < unigrams.length; pos++) {
      const char = unigrams[pos];
      if (char === ' ') { // Space
        testNgrams(pos);
        if (startPositions.length === this.maxNgramSize) { startPositions.shift(); }
        startPositions.push(pos + 1);
      }
    }

    while (startPositions.length > 1) {
      testNgrams(unigrams.length);
      startPositions.shift();
    }

    return ret;
  }
});
