TokenSet = require('./TokenSet')

# A token set built from a function.
#
# For instance, a token set built from the function
# `function(token) { return token.length == 4; }` would only match four-letter
# words.
module.exports = class FunctionTokenSet extends TokenSet
  constructor: (@function, maxNgramSize) ->
    super(maxNgramSize)

  test: (token) -> @function(token)
