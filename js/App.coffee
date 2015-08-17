$ = require('jquery')
oboe = require('oboe')
queryString = require('query-string')

Blacklist = require('./models/Blacklist')
FilterView = require('./views/FilterView')
Filters = require('../lib/Filters')
TokenListView = require('./views/TokenListView')
ProgressView = require('./views/ProgressView')

DefaultFilters =
  include: []
  exclude: [ 'googlebooks-words.eng', 'numbers' ]

module.exports = class App
  constructor: (@$el, @options) ->
    throw 'Must pass options.server, the Overview server URL' if !@options.server
    throw 'Must pass options.documentSetId, a String' if !@options.documentSetId
    throw 'Must pass options.apiToken, a String' if !@options.apiToken

    @_currentStream = null # The current stream, so we can abort it

    # These defaults will kick in if the server has no state; otherwise,
    # setState() will override them.
    @blacklist = new Blacklist()
    @filters =
      include: DefaultFilters.include
      exclude: DefaultFilters.exclude

    @blacklist.on('change', => @_saveState())

  # Starts an HTTP request to stream the tokens again.
  refresh: ->
    options = @_getOptions()
    return if @lastOptions? && @lastOptions.include == options.include && @lastOptions.exclude == options.exclude

    @_currentStream?.abort()

    @tokenListView.setTokenList([]).render()

    @_currentStream = oboe("/generate?#{queryString.stringify(options)}")
      .node '![*]', (obj) =>
        if obj.progress?
          @progressView.setProgress(obj.progress)
        else if obj.tokens?
          @progressView.setProgress(1)
          @tokenListView.setTokenList(obj.tokens).render()
        else
          throw new Error("Unexpected object in stream: #{JSON.stringify(obj)}")
        oboe.drop

    @lastOptions = options

  # Saves the state to the server and refreshes the output.
  #
  # Both are asynchronous calls.
  saveStateAndRefresh: ->
    @_saveState()
    @refresh()

  # Sends an AJAX request to Overview.
  #
  # This is like $.ajax, but it adds @options.server to the (relative) URL and
  # @options.apiToken to an Authorization header.
  _overviewAjax: (options) ->
    obj = {}
    (obj[k] = v) for k, v of options
    obj.url = "#{@options.server}#{obj.url}"
    obj.beforeSend = (xhr) =>
      xhr.setRequestHeader('Authorization', "Basic #{new Buffer("#{@options.apiToken}:x-auth-token").toString('base64')}")
    $.ajax(obj)

  _saveState: ->
    @_overviewAjax
      type: 'PUT'
      url: '/api/v1/store/state'
      contentType: 'application/json'
      data: JSON.stringify(@getState())
      error: (xhr, textStatus, errorThrown) ->
        console.warn("Unexpected error saving state", xhr, textStatus, errorThrown)

  # Queries Overview for initial state, then calls setState() with it.
  start: ->
    @_overviewAjax
      type: 'GET'
      url: '/api/v1/store/state'
      success: (state) => @setState(state)
      error: (xhr, textStatus, errorThrown) =>
        if xhr.status != 404
          console.warn("Unexpected error fetching state", xhr, textStatus, errorThrown)
        @setState({})

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
    include: @filters.include.join(',')
    exclude: @filters.exclude.join(',')

  # Returns the current state, for saving to the server.
  #
  # State schema:
  #
  # * version: 1 # A Number, increments as we change this schema
  # * filters:
  #   * include: { 'id.of.a.filter': { version: 3 }, ... }
  #   * exclude: { 'another.filter': { version: 2 }, ... }
  # * blacklist: [ 'token1', 'token2', ... ]
  getState: ->
    include = {}
    (include[id] = { version: Filters[id].version }) for id in @filters.include

    exclude = {}
    (exclude[id] = { version: Filters[id].version }) for id in @filters.exclude

    version: 1 # First schema
    filters:
      include: include
      exclude: exclude
    blacklist: @blacklist.toArray()

  # Sets the state.
  #
  # The argument is a former return value from a call to getState(). It may
  # also be the empty object (`{}`), to set default state.
  #
  # This call will automatically delete the '.loading' spinner and trigger a
  # server refresh.
  setState: (state) ->
    if state.version? && state.version != 1
      throw new Error("Invalid state object: #{JSON.stringify(state)}")

    # We ignore filter versions for now. (Why did we create filter versions at
    # all? For forwards-compatibility.)
    include = Object.keys(state.filters?.include || {})
    exclude = Object.keys(state.filters?.exclude || {})

    @filters = { include: include, exclude: exclude }
    @filterView.setFilters(@filters)
    @blacklist.reset(state.blacklist || [])
    @$el.children('.loading').remove()
    @refresh()

  # Sets up the HTML
  render: ->
    @$el.html('''
      <div class="loading">
        <div class="spinner"></div>
        <p>Loading…</p>
      </div>
      <div class="panes">
        <div class="filter-list"></div>
        <div class="token-list"></div>
      </div>
      <div class="progress"></div>
    ''')

    @progressView = new ProgressView(@$el.find('.progress')).render()
    @filterView = new FilterView(@$el.find('.filter-list'),
      filters: @filters
      blacklist: @blacklist
      onSelectFilters: (filters) => @filters = filters; @saveStateAndRefresh()
    ).render()
    @tokenListView = new TokenListView(@$el.find('.token-list'),
      blacklist: @blacklist
      doSearch: (token) => @postSearch(token)
    ).render()

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
