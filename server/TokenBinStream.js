/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let TokenBinStream;
const oboe = require('oboe');
const stream = require('stream');
const TokenBin = require('overview-js-token-bin');

const ReadDelay = 500; // ms between read() and push(). If 0, we'll push() non-stop.
const MaxNTokens = 500; // tokens send to client

// Builds a list of wanted Tokens, assuming there are only unigrams in the text.
//
// We have a special code path when we know it's impossible for the result to
// contain anything but unigrams. In that case, we assume the maximum number of
// unique tokens to be <100k, so we just throw every token into one TokenBin
// and then exclude every invalid token from the result.
class UnigramTokenListBuilder {
  constructor(includeFilters, excludeFilters) {
    this.includeFilters = includeFilters;
    this.excludeFilters = excludeFilters;
    this.tokenBin = new TokenBin([]);
  }

  addDocumentTokens(tokensString) {
    const tokens = tokensString.toLowerCase().split(' ');
    return this.tokenBin.addTokens(tokens);
  }

  getTokensByFrequency() {
    let filter;
    let token;
    let ret = this.tokenBin.getTokensByFrequency();

    for (filter of Array.from(this.includeFilters)) {
      ret = ((() => {
        const result = [];
        for (token of Array.from(ret)) {           if (filter.test(token.name)) {
            result.push(token);
          }
        }
        return result;
      })());
    }

    for (filter of Array.from(this.excludeFilters)) {
      ret = ((() => {
        const result1 = [];
        for (token of Array.from(ret)) {           if (!filter.test(token.name)) {
            result1.push(token);
          }
        }
        return result1;
      })());
    }

    for (filter of Array.from(this.includeFilters)) {
      if (filter.getTitle != null) {
        for (token of Array.from(ret)) {
          if (!token.title) {
            const title = filter.getTitle(token.name);
            if (title != null) { token.title = title; }
          }
        }
      }
    }

    return ret;
  }
}

// Builds a list of wanted Tokens, including ngrams.
//
// Since we allow ngrams, we assume there could be an arbitrarily-high number of
// ngrams. To keep memory under control, we can't store unwanted tokens
// temporarily, like we would in UnigramTokenListBuilder.
class NgramTokenListBuilder {
  constructor(includeFilters, excludeFilters) {
    this.includeFilters = includeFilters;
    this.excludeFilters = excludeFilters;
    this.tokenBin = new TokenBin([]);
  }

  addDocumentTokens(tokensString) {
    let token;
    let toAdd = []; // list of all tokens, with repeats
    const toAddSet = {}; // token -> null. Ensure when we union we don't count tokens twice

    for (let filterIndex = 0; filterIndex < this.includeFilters.length; filterIndex++) {
      const filter = this.includeFilters[filterIndex];
      var moreToAdd = filter.findTokensFromUnigrams(tokensString);
      if (toAdd.length) {
        // Remove duplicates: tokens we found in a previous filter
        moreToAdd = ((() => {
          const result = [];
          for (token of Array.from(moreToAdd)) {             if (!(token in toAddSet)) {
              result.push(token);
            }
          }
          return result;
        })());
      }
      if (filterIndex < (this.includeFilters.length - 1)) {
        // Remember these tokens for the next filter
        for (token of Array.from(moreToAdd)) { toAddSet[token] = null; }
      }
      toAdd = toAdd.concat(moreToAdd);
    }

    return this.tokenBin.addTokens(toAdd);
  }

  getTokensByFrequency() {
    let filter;
    let token;
    let ret = this.tokenBin.getTokensByFrequency();

    for (filter of Array.from(this.excludeFilters)) {
      ret = ((() => {
        const result = [];
        for (token of Array.from(ret)) {           if (!filter.test(token.name)) {
            result.push(token);
          }
        }
        return result;
      })());
    }

    for (filter of Array.from(this.includeFilters)) {
      if (filter.getTitle != null) {
        for (token of Array.from(ret)) {
          if (!token.title) {
            const title = filter.getTitle(token.name);
            if (title != null) { token.title = title; }
          }
        }
      }
    }

    return ret;
  }
}

// Outputs JSON objects corresponding to the current status.
//
// Each object looks like this:
//
//   {
//     "progress": <Number between 0.0 and 1.0>,
//     "tokens": [ {
//       "name": "foo",
//       "nDocuments": 2,
//       "frequency": 8
//     }, ... ]
//   }
//
// Any of the above variables may be unset. If `progress` is unset, that means
// it is 1.0.
//
// Callers should handle 'error' events. They do happen.
module.exports = (TokenBinStream = class TokenBinStream extends stream.Readable {
  constructor(options) {
    super({objectMode: true});
    this.options = options;

    if (!this.options.server) { throw new Error('Must pass options.server, the Overview server base URL'); }
    if (!this.options.apiToken) { throw new Error('Must pass options.apiToken, the API token'); }
    if (!this.options.documentSetId) { throw new Error('Must pass options.documentSetId, the document set ID'); }
    if (!this.options.filters) { throw new Error('Must pass options.filters, an Object with `include` and `exclude` Filter arrays'); }

    this._readTimeout = null; // If set, the user called read() and we haven't called push() for it yet

    let unigramsOnly = true;
    for (let filter of Array.from(this.options.filters.include)) {
      if (filter.maxNgramSize > 1) {
        unigramsOnly = false;
        break;
      }
    }

    this.tokenListBuilder = unigramsOnly ?
      new UnigramTokenListBuilder(this.options.filters.include, this.options.filters.exclude)
    :
      new NgramTokenListBuilder(this.options.filters.include, this.options.filters.exclude);

    this.nDocuments = 0;
    this.nDocumentsTotal = 1;
  }

  _start() {
    this.stream = oboe({
      url: `${this.options.server}/api/v1/document-sets/${this.options.documentSetId}/documents?fields=tokens&stream=true`,
      headers: {
        Authorization: `Basic ${Buffer.from(`${this.options.apiToken}:x-auth-token`, 'ascii').toString('base64')}`
      }
    });

    this.stream.node('pagination.total', total => { this.nDocumentsTotal = total; return oboe.drop; });
    this.stream.node('items.*', document => { this._onDocumentTokens(document.tokens); return oboe.drop; });
    this.stream.fail(err => this._onStreamError(err));
    return this.stream.done(() => this._onStreamDone());
  }

  // stream.Readable Contract: schedules a .push().
  _read() {
    if (this._readTimeout != null) { return; }
    if ((this.stream == null)) { this._start(); }
    return this._readTimeout = setTimeout((() => this._onPushNeeded()), ReadDelay);
  }

  // Calls .push() with the current status.
  //
  // After this method returns, callers may call ._read() again.
  _onPushNeeded() {
    this._readTimeout = null; // Before the push(), so that _read() works
    return this.push({progress: this.nDocuments / this.nDocumentsTotal});
  }

  // Handles a single document's text
  _onDocumentTokens(tokensString) {
    this.tokenListBuilder.addDocumentTokens(tokensString);
    return this.nDocuments += 1;
  }

  _clearReadTimeout() {
    clearTimeout(this._readTimeout);
    return this._readTimeout = null;
  }

  // Sends the final results, then EOF
  _onStreamDone() {
    this.push({tokens: this.tokenListBuilder.getTokensByFrequency().slice(0, MaxNTokens)});
    this.push(null);

    return this._clearReadTimeout(); // No more reads, please
  }

  // Sends an error, then EOF
  _onStreamError(err) {
    if (this.destroyed) { return; } // oboe creates an error when we abort it.

    if (err.statusCode != null) {
      this.emit('error', new Error(`Overview server responded: ${JSON.stringify(err)}`));
    } else {
      this.emit('error', err);
    }

    return this._clearReadTimeout(); // No more reads, please
  }

  // Stops streaming from Overview.
  //
  // Callers should call this when the client stops listening.
  destroy() {
    this.destroyed = true;
    if (this.stream != null) {
      this.stream.abort();
    } // It might be the case that @stream was never created

    return this._clearReadTimeout(); // No more reads, please
  }
});
