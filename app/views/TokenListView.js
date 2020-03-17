/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let TokenListView;
const $ = require('jquery');
const template = require('lodash.template');
const numeral = require('numeral');

module.exports = (TokenListView = (function() {
  TokenListView = class TokenListView {
    static initClass() {
  
      this.prototype.template = template(`\
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
</table>\
`);
    }
    constructor($el, options) {
      this.$el = $el;
      if (options == null) { options = {}; }
      if (!('doSearch' in options)) { throw 'Must pass options.doSearch, a Function'; }
      if (!('blacklist' in options)) { throw 'Must pass options.blacklist, a Blacklist'; }

      this.blacklist = options.blacklist;
      this._doSearch = options.doSearch;

      this.tokenList = [];

      this.$el.on('click', 'td.token', e => this._onClickToken(e));
      this.$el.on('click', 'button.blacklist', e => this._onClickBlacklist(e));
      this.blacklist.on('change', () => this._renderBlacklist());

      $(window).resize(() => this._renderTooWide());
    }

    // Sets a new token list. Call render() after calling this.
    setTokenList(tokenList) { this.tokenList = tokenList; return this; }

    // Renders the token list.
    render() {
      let trs;
      const html = this.template({
        tokenList: this.tokenList,
        numeral
      });
      this.$el.html(html);

      this.$table = this.$el.find('table');
      this.trs = (trs = {}); // Hash of token-name to <tr> HTMLElement

      for (let tr of Array.from(this.$el.find('tr[data-token-name]'))) {
        trs[tr.getAttribute('data-token-name')] = tr;
      }

      this._renderBlacklist();
      this._renderTooWide();
      return this;
    }

    _renderBlacklist() {
      for (let tokenName in this.trs) {
        const tr = this.trs[tokenName];
        tr.className = this.blacklist.contains(tokenName) ? 'hide' : '';
      }
      return null;
    }

    _renderTooWide() {
      if ((this.$table == null)) { return; }

      this.$table.removeClass('too-wide');
      if (this.$table.width() > this.$el.width()) {
        return this.$table.addClass('too-wide');
      }
    }

    _onClickToken(e) {
      const tr = e.currentTarget.parentNode;
      const token = tr.getAttribute('data-token-name');
      return this._doSearch(token);
    }

    _onClickBlacklist(e) {
      const tokenName = e.currentTarget.getAttribute('data-token-name');
      return this.blacklist.insert(tokenName);
    }
  };
  TokenListView.initClass();
  return TokenListView;
})());
