/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let App;
const $ = require('jquery');
const oboe = require('oboe');

const Blacklist = require('./models/Blacklist');
const FilterView = require('./views/FilterView');
const Filters = require('../server/Filters');
const TokenListView = require('./views/TokenListView');
const ProgressView = require('./views/ProgressView');

const DefaultFilters = {
  include: [],
  exclude: [ 'googlebooks-words.eng', 'numbers' ]
};

module.exports = (App = class App {
  constructor($el, options) {
    this.$el = $el;
    this.options = options;
    if (!this.options.server) { throw 'Must pass options.server, the Overview server URL'; }
    if (!this.options.documentSetId) { throw 'Must pass options.documentSetId, a String'; }
    if (!this.options.apiToken) { throw 'Must pass options.apiToken, a String'; }

    this._currentStream = null; // The current stream, so we can abort it

    // These defaults will kick in if the server has no state; otherwise,
    // setState() will override them.
    this.blacklist = new Blacklist();
    this.filters = DefaultFilters;

    this.blacklist.on('change', () => this._saveState());
  }

  // Starts an HTTP request to stream the tokens again.
  refresh() {
    const optionsString = this._getOptionsString();
    if (this.lastOptionsString === optionsString) { return; }

    if (this._currentStream != null) {
      this._currentStream.abort();
    }

    this.tokenListView.setTokenList([]).render();

    this._currentStream = oboe(`/generate?${optionsString}`)
      .node('![*]', obj => {
        if (obj.progress != null) {
          this.progressView.setProgress(obj.progress);
        } else if (obj.tokens != null) {
          this.progressView.setProgress(1);
          this.tokenListView.setTokenList(obj.tokens).render();
        } else {
          throw new Error(`Unexpected object in stream: ${JSON.stringify(obj)}`);
        }
        return oboe.drop;
    });

    return this.lastOptionsString = optionsString;
  }

  // Saves the state to the server and refreshes the output.
  //
  // Both are asynchronous calls.
  saveStateAndRefresh() {
    this._saveState();
    return this.refresh();
  }

  // Sends an AJAX request to Overview.
  //
  // This is like $.ajax, but it adds @options.origin to the (relative) URL and
  // @options.apiToken to an Authorization header.
  _overviewAjax(options) {
    const obj = {};
    for (let k in options) { const v = options[k]; obj[k] = v; }
    obj.url = `${this.options.origin}${obj.url}`;
    obj.beforeSend = xhr => {
      return xhr.setRequestHeader('Authorization', `Basic ${new Buffer(`${this.options.apiToken}:x-auth-token`).toString('base64')}`);
    };
    return $.ajax(obj);
  }

  _saveState() {
    return this._overviewAjax({
      type: 'PUT',
      url: '/api/v1/store/state',
      contentType: 'application/json',
      data: JSON.stringify(this.getState()),
      error(xhr, textStatus, errorThrown) {
        return console.warn("Unexpected error saving state", xhr, textStatus, errorThrown);
      }
    });
  }

  // Queries Overview for initial state, then calls setState() with it.
  start() {
    return this._overviewAjax({
      type: 'GET',
      url: '/api/v1/store/state',
      success: state => {
        // Sanitize state. Useful when debugging plugins and we get the state
        // from a different plugin
        state = {
          version: 1,
          filters: (((state != null ? state.version : undefined) === 1) && state.filters) || {
            include: {},
            exclude: { 'googlebooks-words.eng': null, 'numbers': null }
          },
          blacklist: (((state != null ? state.version : undefined) === 1) && state.blacklist) || []
        };
        return this.setState(state);
      },
      error: (xhr, textStatus, errorThrown) => {
        if (xhr.status !== 404) {
          console.warn("Unexpected error fetching state", xhr, textStatus, errorThrown);
        }
        return this.setState({});
      }
    });
  }

  // Returns the query-string we'll pass to /generate.
  //
  // Parameters:
  //
  // * `server`
  // * `documentSetId`
  // * `apiToken`
  // * `include`, a comma-separated list of Strings
  // * `exclude`, a comma-separated list of Strings
  _getOptionsString() {
    const params = [
      [ 'server', this.options.server ],
      [ 'documentSetId', this.options.documentSetId ],
      [ 'apiToken', this.options.apiToken ],
      [ 'include', this.filters.include.join(',') ],
      [ 'exclude', this.filters.exclude.join(',') ]
    ];

    return params
      .map(arr => `${encodeURIComponent(arr[0])}=${encodeURIComponent(arr[1])}`)
      .join('&');
  }

  // Returns the current state, for saving to the server.
  //
  // State schema:
  //
  // * version: 1 # A Number, increments as we change this schema
  // * filters:
  //   * include: { 'id.of.a.filter': { version: 3 }, ... }
  //   * exclude: { 'another.filter': { version: 2 }, ... }
  // * blacklist: [ 'token1', 'token2', ... ]
  getState() {
    let id;
    const include = {};
    for (id of Array.from(this.filters.include)) { include[id] = { version: Filters[id].version }; }

    const exclude = {};
    for (id of Array.from(this.filters.exclude)) { exclude[id] = { version: Filters[id].version }; }

    return {
      version: 1, // First schema
      filters: {
        include,
        exclude
      },
      blacklist: this.blacklist.toArray()
    };
  }

  // Sets the state.
  //
  // The argument is a former return value from a call to getState(). It may
  // also be the empty object (`{}`), to set default state.
  //
  // This call will automatically delete the '.loading' spinner and trigger a
  // server refresh.
  setState(state) {
    if ((state.version != null) && (state.version !== 1)) {
      throw new Error(`Invalid state object: ${JSON.stringify(state)}`);
    }

    if ('filters' in state) {
      // We ignore filter versions for now. (Why did we create filter versions at
      // all? For forwards-compatibility.)
      const include = Object.keys(state.filters.include || {});
      const exclude = Object.keys(state.filters.exclude || {});

      this.filters = { include, exclude };
      this.filterView.setFilters(this.filters);
    }

    if ('blacklist' in state) {
      this.blacklist.reset(state.blacklist || []);
    }

    this.$el.children('.loading').remove();
    return this.refresh();
  }

  // Sets up the HTML
  render() {
    this.$el.html(`\
<div class="loading">
  <div class="spinner"></div>
  <p>Loading…</p>
</div>
<div class="panes">
  <div class="filter-list"></div>
  <div class="token-list"></div>
</div>
<div class="progress"></div>\
`);

    this.progressView = new ProgressView(this.$el.find('.progress')).render();
    this.filterView = new FilterView(this.$el.find('.filter-list'), {
      filters: this.filters,
      blacklist: this.blacklist,
      onSelectFilters: filters => { this.filters = filters; return this.saveStateAndRefresh(); }
    }
    ).render();
    this.tokenListView = new TokenListView(this.$el.find('.token-list'), {
      blacklist: this.blacklist,
      doSearch: token => this.postSearch(token)
    }
    ).render();

    return this;
  }

  // Tells the parent frame to search for a token
  postSearch(token) {
    const quotedToken = /\b(and|or|not)\b/.test(token) ?
      // Put the token in quotes. This is hardly a perfect quoting mechanism,
      // but it should handle all real-world use cases.
      `\"${token}\"`
    :
      token;

    return window.parent.postMessage({
      call: 'setDocumentListParams',
      args: [ {q: `text:${quotedToken}` } ]
    }, this.options.origin);
  }
});
