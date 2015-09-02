oboe = require('oboe')
stream = require('stream')
TokenBin = require('overview-js-token-bin')

ReadDelay = 500 # ms between read() and push(). If 0, we'll push() non-stop.
MaxNTokens = 500 # tokens send to client

# Builds a list of wanted Tokens, assuming there are only unigrams in the text.
#
# We have a special code path when we know it's impossible for the result to
# contain anything but unigrams. In that case, we assume the maximum number of
# unique tokens to be <100k, so we just throw every token into one TokenBin
# and then exclude every invalid token from the result.
class UnigramTokenListBuilder
  constructor: (@includeFilters, @excludeFilters) ->
    @tokenBin = new TokenBin([])

  addDocumentTokens: (tokensString) ->
    tokens = tokensString.toLowerCase().split(' ')
    @tokenBin.addTokens(tokens)

  getTokensByFrequency: ->
    ret = @tokenBin.getTokensByFrequency()

    for filter in @includeFilters
      ret = (token for token in ret when filter.test(token.name))

    for filter in @excludeFilters
      ret = (token for token in ret when !filter.test(token.name))

    for filter in @includeFilters when filter.getTitle?
      for token in ret when !token.title
        title = filter.getTitle(token.name)
        token.title = title if title?

    ret

# Builds a list of wanted Tokens, including ngrams.
#
# Since we allow ngrams, we assume there could be an arbitrarily-high number of
# ngrams. To keep memory under control, we can't store unwanted tokens
# temporarily, like we would in UnigramTokenListBuilder.
class NgramTokenListBuilder
  constructor: (@includeFilters, @excludeFilters) ->
    @tokenBin = new TokenBin([])

  addDocumentTokens: (tokensString) ->
    toAdd = [] # list of all tokens, with repeats
    toAddSet = {} # token -> null. Ensure when we union we don't count tokens twice

    for filter, filterIndex in @includeFilters
      moreToAdd = filter.findTokensFromUnigrams(tokensString)
      if toAdd.length
        # Remove duplicates: tokens we found in a previous filter
        moreToAdd = (token for token in moreToAdd when token not of toAddSet)
      if filterIndex < @includeFilters.length - 1
        # Remember these tokens for the next filter
        (toAddSet[token] = null) for token in moreToAdd
      toAdd = toAdd.concat(moreToAdd)

    @tokenBin.addTokens(toAdd)

  getTokensByFrequency: ->
    ret = @tokenBin.getTokensByFrequency()

    for filter in @excludeFilters
      ret = (token for token in ret when !filter.test(token.name))

    for filter in @includeFilters when filter.getTitle?
      for token in ret when !token.title
        title = filter.getTitle(token.name)
        token.title = title if title?

    ret

# Outputs JSON objects corresponding to the current status.
#
# Each object looks like this:
#
#   {
#     "progress": <Number between 0.0 and 1.0>,
#     "tokens": [ {
#       "name": "foo",
#       "nDocuments": 2,
#       "frequency": 8
#     }, ... ]
#   }
#
# Any of the above variables may be unset. If `progress` is unset, that means
# it is 1.0.
#
# Callers should handle 'error' events. They do happen.
module.exports = class TokenBinStream extends stream.Readable
  constructor: (@options) ->
    throw new Error('Must pass options.server, the Overview server base URL') if !@options.server
    throw new Error('Must pass options.apiToken, the API token') if !@options.apiToken
    throw new Error('Must pass options.documentSetId, the document set ID') if !@options.documentSetId
    throw new Error('Must pass options.filters, an Object with `include` and `exclude` Filter arrays') if !@options.filters

    super(objectMode: true)

    @_readTimeout = null # If set, the user called read() and we haven't called push() for it yet

    unigramsOnly = true
    for filter in @options.filters.include when filter.maxNgramSize > 1
      unigramsOnly = false
      break

    @tokenListBuilder = if unigramsOnly
      new UnigramTokenListBuilder(@options.filters.include, @options.filters.exclude)
    else
      new NgramTokenListBuilder(@options.filters.include, @options.filters.exclude)

    @nDocuments = 0
    @nDocumentsTotal = 1

  _start: ->
    @stream = oboe
      url: "#{@options.server}/api/v1/document-sets/#{@options.documentSetId}/documents?fields=tokens&stream=true"
      headers:
        Authorization: "Basic #{new Buffer("#{@options.apiToken}:x-auth-token", 'ascii').toString('base64')}"

    @stream.node('pagination.total', (total) => @nDocumentsTotal = total; oboe.drop)
    @stream.node('items.*', (document) => @_onDocumentTokens(document.tokens); oboe.drop)
    @stream.fail((err) => @_onStreamError(err))
    @stream.done(=> @_onStreamDone())

  # stream.Readable Contract: schedules a .push().
  _read: ->
    return if @_readTimeout?
    @_start() if !@stream?
    @_readTimeout = setTimeout((=> @_onPushNeeded()), ReadDelay)

  # Calls .push() with the current status.
  #
  # After this method returns, callers may call ._read() again.
  _onPushNeeded: ->
    @_readTimeout = null # Before the push(), so that _read() works
    @push(progress: @nDocuments / @nDocumentsTotal)

  # Handles a single document's text
  _onDocumentTokens: (tokensString) ->
    @tokenListBuilder.addDocumentTokens(tokensString)
    @nDocuments += 1

  _clearReadTimeout: ->
    clearTimeout(@_readTimeout)
    @_readTimeout = null

  # Sends the final results, then EOF
  _onStreamDone: ->
    @push(tokens: @tokenListBuilder.getTokensByFrequency().slice(0, MaxNTokens))
    @push(null)

    @_clearReadTimeout() # No more reads, please

  # Sends an error, then EOF
  _onStreamError: (err) ->
    return if @destroyed # oboe creates an error when we abort it.

    if err.statusCode?
      @emit('error', new Error("Overview server responded: #{JSON.stringify(err)}"))
    else
      @emit('error', err)

    @_clearReadTimeout() # No more reads, please

  # Stops streaming from Overview.
  #
  # Callers should call this when the client stops listening.
  destroy: ->
    @destroyed = true
    @stream?.abort() # It might be the case that @stream was never created

    @_clearReadTimeout() # No more reads, please
