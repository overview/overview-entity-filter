fs = require('fs')
zlib = require('zlib')

TokenSet = require('./TokenSet')
NativeSet = require('js-native-ternary-buffer-tree')

# A token set built from a bunch of text.
#
# The file must be UTF8-encoded text, tokens separated by '\n', lines sorted by
# Unicode code point. (Hint: `LC_ALL=C sort -u` gives this ordering.) It may be
# gzipped.
#
# On first `test()`, the actual data will be loaded synchronously from the
# filesystem. This can be slow; if you want to take that hit at a predictable
# time, call `test("")` directly.
module.exports = class TextTokenSet extends TokenSet
  constructor: (@path, maxNgramSize) ->
    super(maxNgramSize)

  _getSet: ->
    @set ?= (=>
      buffer = fs.readFileSync(@path)
      buffer = zlib.gunzipSync(buffer) if /\.gz$/.test(@path)
      new NativeSet(buffer)
    )()

  test: (token, start, end) ->
    @_getSet().contains(token.slice(start, end))

  findTokensFromUnigrams: (unigrams) ->
    unigramsBuffer = new Buffer(unigrams.join(' ').toLowerCase(), 'utf-8') # Encode as binary
    @_getSet().findAllMatches(unigramsBuffer, @maxNgramSize)

class TextTokenSet.Factory
  constructor: (@path, @maxNgramSize) ->

  load: -> new TextTokenSet(@path, @maxNgramSize)
