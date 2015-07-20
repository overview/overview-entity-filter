template = require('lodash.template')

module.exports = class TokenListView
  constructor: (@$el) ->
    @tokenList = []

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
    console.log(html)
    @$el.html(html)
    @
