$ = require('jquery')
template = require('lodash.template')

module.exports = class TokenListView
  constructor: (@$el, options={}) ->
    throw 'Must pass options.doSearch, a Function' if 'doSearch' not of options

    @_doSearch = options.doSearch

    @tokenList = []

    @$el.on('click', 'td.name', (e) => @_onClickName(e))

  template: template('''
    <table>
      <thead>
        <tr>
          <th class="name">Entity</th>
          <th class="frequency">count</th>
          <th class="n-documents">documents</th>
        </tr>
      </thead>
      <tbody>
        <% tokenList.forEach(function(token) { %>
          <tr>
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
    @

  _onClickName: (e) ->
    token = $(e.currentTarget).text()
    @_doSearch(token)
