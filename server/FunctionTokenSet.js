let FunctionTokenSet;
const TokenSet = require('./TokenSet');

// A token set built from a function.
//
// For instance, a token set built from the function
// `function(token) { return token.length == 4; }` would only match four-letter
// words.
module.exports = (FunctionTokenSet = class FunctionTokenSet extends TokenSet {
  constructor(function1, maxNgramSize) {
    super(maxNgramSize);
    this.function = function1;
  }

  test(token) { return this.function(token); }
});
