$ = require('jquery')
template = require('lodash.template')

module.exports = class TokenListView
  constructor: (@$el, options={}) ->
    throw 'Must pass options.doSearch, a Function' if 'doSearch' not of options
    throw 'Must pass options.blacklist, a Blacklist' if 'blacklist' not of options

    @blacklist = options.blacklist
    @_doSearch = options.doSearch

    @tokenList = []

    @$el.on('click', 'td.name', (e) => @_onClickName(e))
    @$el.on('click', 'button.blacklist', (e) => @_onClickBlacklist(e))
    @blacklist.on('change', => @_renderBlacklist())

  template: template('''
    <table>
      <thead>
        <tr>
          <th class="actions" />
          <th class="name">Entity</th>
          <th class="frequency">count</th>
          <th class="n-documents">docs</th>
        </tr>
      </thead>
      <tbody>
        <% tokenList.forEach(function(token) { %>
          <tr>
            <td class="actions"><button type="button" class="blacklist" title="Hide this entity" data-token-name="<%- token.name %>">&times;</button></td>
            <td class="name"><%- token.name %></td>
            <td class="frequency"><%- token.frequency %></td>
            <td class="n-documents"><%- token.nDocuments %></td>
          </tr>
        <% }); %>
      </tbody>
    </table>
  ''')

  # Sets a new token list. Call render() after calling this.
  setTokenList: (@tokenList) -> @

  # Renders the token list.
  render: ->
    html = @template(tokenList: @tokenList)
    @$el.html(html)

    @trs = trs = {} # Hash of token-name to <tr> HTMLElement

    for td in @$el.find('td.name')
      trs[$(td).text()] = td.parentNode

    @_renderBlacklist()
    @

  _renderBlacklist: ->
    for tokenName, tr of @trs
      tr.className = if @blacklist.contains(tokenName) then 'hide' else ''

  _onClickName: (e) ->
    token = $(e.currentTarget).text()
    @_doSearch(token)

  _onClickBlacklist: (e) ->
    tokenName = e.currentTarget.getAttribute('data-token-name')
    @blacklist.insert(tokenName)
