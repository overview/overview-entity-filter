$ = require('jquery')
oboe = require('oboe')
queryString = require('query-string')

FilterView = require('./views/FilterView')
TokenListView = require('./views/TokenListView')
ProgressView = require('./views/ProgressView')

module.exports = class App
  constructor: (@$el, @options) ->
    throw 'Must pass options.server, the Overview server URL' if !@options.server
    throw 'Must pass options.documentSetId, a String' if !@options.documentSetId
    throw 'Must pass options.apiToken, a String' if !@options.apiToken

    @_currentStream = null # The current stream, so we can abort it
    @filters = [ 'location' ] # Array of String filter keys

  # Starts an HTTP request to stream the tokens again
  refresh: ->
    @_currentStream?.abort()

    @tokenListView.setTokenList([]).render()

    @_currentStream = oboe("/generate?#{queryString.stringify(@_getOptions())}")
      .node '![*]', (obj) =>
        if obj.progress?
          @progressView.setProgress(obj.progress)
        else if obj.tokens?
          @progressView.setProgress(1)
          @tokenListView.setTokenList(obj.tokens).render()
        else
          throw new Error("Unexpected object in stream: #{JSON.stringify(obj)}")
        oboe.drop

  # Returns the query-string options we'll pass to /generate.
  #
  # These are:
  #
  # * `server`
  # * `documentSetId`
  # * `apiToken`
  # * `filters`, a comma-separated list of Strings
  _getOptions: ->
    server: @options.server
    documentSetId: @options.documentSetId
    apiToken: @options.apiToken
    filters: @filters

  # Sets up the HTML
  render: ->
    @filterView = new FilterView()
    @tokenListView = new TokenListView()

    @$el.html('''
      <div class="panes">
        <div class="filter"></div>
        <div class="token-list"></div>
      </div>
      <div class="progress"></div>
    ''')

    @progressView = new ProgressView(@$el.find('.progress')).render()
    @filterView = new FilterView(@$el.find('.filter')).render()
    @tokenListView = new TokenListView(@$el.find('.token-list')).render()

    @
