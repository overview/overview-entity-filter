$ = require('jquery')
template = require('lodash.template')
numeral = require('numeral')

module.exports = class TokenListView
  constructor: (@$el, options={}) ->
    throw 'Must pass options.doSearch, a Function' if 'doSearch' not of options
    throw 'Must pass options.blacklist, a Blacklist' if 'blacklist' not of options

    @blacklist = options.blacklist
    @_doSearch = options.doSearch

    @tokenList = []

    @$el.on('click', 'td.token', (e) => @_onClickToken(e))
    @$el.on('click', 'button.blacklist', (e) => @_onClickBlacklist(e))
    @blacklist.on('change', => @_renderBlacklist())

    $(window).resize(=> @_renderTooWide())

  template: template('''
    <table>
      <thead>
        <tr>
          <th class="actions" />
          <th class="token">Entity</th>
          <th class="frequency">count</th>
          <th class="n-documents">docs</th>
        </tr>
      </thead>
      <tbody>
        <% tokenList.forEach(function(token) { %>
          <tr data-token-name="<%- token.name %>">
            <td class="actions"><button type="button" class="blacklist" title="Hide this entity" data-token-name="<%- token.name %>">&times;</button></td>
            <td class="token">
              <span class="name"><%- token.name %></span>
              <% if (token.title) { %>
                <span class="title"><%- token.title %></span>
              <% } %>
            </td>
            <td class="frequency"><%- numeral(token.frequency).format('0,0') %></td>
            <td class="n-documents"><%- numeral(token.nDocuments).format('0,0') %></td>
          </tr>
        <% }); %>
      </tbody>
    </table>
  ''')

  # Sets a new token list. Call render() after calling this.
  setTokenList: (@tokenList) -> @

  # Renders the token list.
  render: ->
    html = @template
      tokenList: @tokenList
      numeral: numeral
    @$el.html(html)

    @$table = @$el.find('table')
    @trs = trs = {} # Hash of token-name to <tr> HTMLElement

    for tr in @$el.find('tr[data-token-name]')
      trs[tr.getAttribute('data-token-name')] = tr

    @_renderBlacklist()
    @_renderTooWide()
    @

  _renderBlacklist: ->
    for tokenName, tr of @trs
      tr.className = if @blacklist.contains(tokenName) then 'hide' else ''
    null

  _renderTooWide: ->
    return if !@$table?

    @$table.removeClass('too-wide')
    if @$table.width() > @$el.width()
      @$table.addClass('too-wide')

  _onClickToken: (e) ->
    tr = e.currentTarget.parentNode
    token = tr.getAttribute('data-token-name')
    @_doSearch(token)

  _onClickBlacklist: (e) ->
    tokenName = e.currentTarget.getAttribute('data-token-name')
    @blacklist.insert(tokenName)
