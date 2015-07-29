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
    @include = []
    @exclude = []

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
  # * `include`, a comma-separated list of Strings
  # * `exclude`, a comma-separated list of Strings
  _getOptions: ->
    server: @options.server
    documentSetId: @options.documentSetId
    apiToken: @options.apiToken
    include: (@include || []).join(',')
    exclude: (@exclude || []).join(',')

  # Sets up the HTML
  render: ->
    @$el.html('''
      <div class="panes">
        <div class="filter-list"></div>
        <div class="token-list"></div>
      </div>
      <div class="progress"></div>
    ''')

    @progressView = new ProgressView(@$el.find('.progress')).render()
    @filterView = new FilterView(
      @$el.find('.filter-list'),
      include: []
      exclude: []
      onSetInclude: (include) => @include = include; @refresh()
      onSetExclude: (exclude) => @exclude = exclude; @refresh()
    ).render()
    @tokenListView = new TokenListView(@$el.find('.token-list'), doSearch: (token) => @postSearch(token)).render()

    @

  # Tells the parent frame to search for a token
  postSearch: (token) ->
    quotedToken = if /\b(and|or|not)\b/.test(token)
      # Put the token in quotes. This is hardly a perfect quoting mechanism,
      # but it should handle all real-world use cases.
      "\"#{token}\""
    else
      token

    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ q: quotedToken ]
    }, @options.server)
