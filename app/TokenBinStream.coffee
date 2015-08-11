oboe = require('oboe')
stream = require('stream')
tokenize = require('overview-js-tokenizer').tokenize
TokenBin = require('overview-js-token-bin')

ReadDelay = 500 # ms between read() and push(). If 0, we'll push() non-stop.
MaxNTokens = 500 # tokens send to client

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
# Handle errors, too: they do happen.
module.exports = class TokenBinStream extends stream.Readable
  constructor: (@options) ->
    throw new Error('Must pass options.server, the Overview server base URL') if !@options.server
    throw new Error('Must pass options.apiToken, the API token') if !@options.apiToken
    throw new Error('Must pass options.documentSetId, the document set ID') if !@options.documentSetId
    throw new Error('Must pass options.filters, an Object with `include` and `exclude` Filter arrays') if !@options.filters

    super(objectMode: true)

    @_readTimeout = null # If set, the user called read() and we haven't called push() for it yet

    @nDocuments = 0
    @nDocumentsTotal = 1
    @tokenBin = new TokenBin([])

  _start: ->
    @stream = oboe
      url: "#{@options.server}/api/v1/document-sets/#{@options.documentSetId}/documents?fields=text&stream=true"
      headers:
        Authorization: "Basic #{new Buffer("#{@options.apiToken}:x-auth-token", 'ascii').toString('base64')}"

    @stream.node('pagination.total', (total) => @nDocumentsTotal = total; oboe.drop)
    @stream.node('items.*', (document) => @_onDocumentText(document.text); oboe.drop)
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
  _onDocumentText: (text) ->
    tokens = tokenize(text.toLowerCase())

    includeFilters = @options.filters.include
    excludeFilters = @options.filters.exclude

    toAdd = [] # list of all tokens, with repeats
    toAddSet = {} # token -> null. Ensure when we union we don't count tokens twice

    # Tokens aren't unigrams here, so there could be a crazy number of them. We
    # need to filter them before adding to the TokenBin.
    if includeFilters.length
      tokensString = tokens.join(' ')
      for filter, filterIndex in includeFilters
        moreToAdd = filter.findTokensFromUnigrams(tokensString)
        if toAdd.length
          # Remove duplicates: tokens we found in a previous filter
          moreToAdd = (token for token in moreToAdd when token not of toAddSet)
        if filterIndex < includeFilters.length - 1
          # Remember these tokens for the next filter
          (toAddSet[token] = null) for token in moreToAdd
        toAdd = toAdd.concat(moreToAdd)
    else
      toAdd = tokens

    for excludeFilter in excludeFilters
      newToAdd = (token for token in toAdd when !excludeFilter.test(token))
      toAdd = newToAdd

    @tokenBin.addTokens(toAdd)

    @nDocuments += 1

  _clearReadTimeout: ->
    clearTimeout(@_readTimeout)
    @_readTimeout = null

  # Sends the final results, then EOF
  _onStreamDone: ->
    @push(tokens: @tokenBin.getTokensByFrequency().slice(0, MaxNTokens))
    @push(null)

    @_clearReadTimeout() # No more reads, please

  # Sends an error, then EOF
  _onStreamError: (err) ->
    if err.statusCode?
      @emit('error', new Error("Overview server responded: #{JSON.stringify(err)}"))
    else
      @emit('error', err)

    @_clearReadTimeout() # No more reads, please

  # Stops streaming from Overview.
  #
  # Callers should call this when the client stops listening.
  destroy: ->
    @stream.abort()

    @_clearReadTimeout() # No more reads, please
