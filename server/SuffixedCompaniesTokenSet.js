/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let SuffixedCompaniesTokenSet;
const TokenSet = require('./TokenSet');

const Suffixes = [
  'AG',
  'B.V',
  'BV',
  'Corp',
  'Corporation',
  'CORP',
  'CORPORATION',
  'GmbH',
  'GMBH',
  'Inc',
  'INC',
  'Incorporated',
  'INCORPORATED',
  'LLC',
  'Ltd',
  'LTD',
  'Limited',
  'LIMITED',
  'Pty',
  'PTY',
  'S.A',
  'SA'
];

const SuffixesSet = {};
for (let suffix of Array.from(Suffixes)) { SuffixesSet[suffix] = null; }

// A token set built by searching backwards after finding company suffixes.
//
// For instance, take the sentence: "I like Acme Corp and Acme Corp likes me."
// This logic will move forward until it finds "Corp", then it will check that
// "Acme" is capitalized, then it will see that "like" is not capitalized; as a
// result, it will output "Acme Corp".
module.exports = (SuffixedCompaniesTokenSet = class SuffixedCompaniesTokenSet extends TokenSet {
  constructor(maxNgramSize) {
    super(maxNgramSize);
  }

  test(token) { return false; }

  findTokensFromUnigrams(unigrams) {
    unigrams = unigrams.split(' '); // Still capitalized
    const ret = [];

    let i = 1;
    let tokenEnd = null; // The suffix: find this first
    let tokenStart = null; // The first capitalized word before it: backtrack to find this
    while (i < unigrams.length) {
      if (unigrams[i] in SuffixesSet) {
        tokenEnd = i;
        tokenStart = i;

        while (true) {
          if (tokenStart <= 0) { break; } // No more words to check
          if (((tokenStart - 1) + this.maxNgramSize) <= tokenEnd) { break; } // Too long
          const word = unigrams[tokenStart - 1];
          if (word in SuffixesSet) { break; } // We're reading a list of companies, and this is the end of a previous one
          const char = word[0];
          if (char.toUpperCase() !== char) { break; } // We've reached a non-capitalized word
          tokenStart -= 1;
        }

        if (tokenStart < tokenEnd) {
          ret.push(unigrams.slice(tokenStart , + tokenEnd + 1 || undefined).join(' '));
        }
      }

      i += 1;
    }

    return ret;
  }
});
