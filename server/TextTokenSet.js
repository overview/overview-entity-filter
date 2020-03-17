let TextTokenSet;
const fs = require('fs');
const zlib = require('zlib');

const TokenSet = require('./TokenSet');
const NativeSet = require('js-native-ternary-buffer-tree');

// A token set built from a bunch of text.
//
// The file must be UTF8-encoded text, tokens separated by '\n', lines sorted by
// Unicode code point. (Hint: `LC_ALL=C sort -u` gives this ordering.) It may be
// gzipped.
//
// On first `test()`, the actual data will be loaded synchronously from the
// filesystem. This can be slow; if you want to take that hit at a predictable
// time, call `test("")` directly.
module.exports = (TextTokenSet = class TextTokenSet extends TokenSet {
  constructor(path, maxNgramSize) {
    super(maxNgramSize);
    this.path = path;
  }

  _getSet() {
    if (this.set == null) {
      let buffer = fs.readFileSync(this.path);
      if (/\.gz$/.test(this.path)) { buffer = zlib.gunzipSync(buffer); }
      this.set = new NativeSet(buffer);
    }
    return this.set
  }

  test(token) { return this._getSet().contains(token); }

  getTitle(token) { return this._getSet().get(token); }

  findTokensFromUnigrams(unigrams) {
    return this._getSet().findAllMatches(unigrams.toLowerCase(), this.maxNgramSize);
  }
});
