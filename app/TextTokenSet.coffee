fs = require('fs')
zlib = require('zlib')

TokenSet = require('./TokenSet')
NativeSet = require('js-native-ternary-buffer-tree')

# A token set built from a bunch of text.
#
# The text must be a '\n'-separated list of tokens, sorted by Unicode codepoint.
# (We'll be using binary search to find tokens.)
module.exports = class TextTokenSet extends TokenSet
  constructor: (buffer, maxNgramSize) ->
    super(maxNgramSize)

    @set = new NativeSet(buffer)

  test: (token, start, end) ->
    @set.contains(token.slice(start, end))

  findTokensFromUnigrams: (unigrams) ->
    unigramsBuffer = new Buffer(unigrams.join(' ').toLowerCase(), 'utf-8') # Encode as binary
    @set.findAllMatches(unigramsBuffer, @maxNgramSize)

# Loads a TextTokenSet from a file path.
#
# The file must be UTF8-encoded text, tokens separated by '\n', lines sorted by
# Unicode code point. (Hint: `LC_ALL=C sort -u` gives this ordering.) It may be
# gzipped.
TextTokenSet.loadSync = (path, maxNgramSize) ->
  buffer = fs.readFileSync(path)

  buffer = zlib.gunzipSync(buffer) if /\.gz$/.test(path)

  new TextTokenSet(buffer, maxNgramSize)

class TextTokenSet.Factory
  constructor: (@path, @maxNgramSize) ->

  loadSync: -> TextTokenSet.loadSync(@path, @maxNgramSize)
