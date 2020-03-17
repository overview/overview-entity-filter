let Blacklist;
const events = require('events');
const Set = require('js-sorted-set');

// A sorted set of token names.
module.exports = (Blacklist = class Blacklist extends events.EventEmitter {
  constructor() {
    super();

    this.tokenSet = new Set({
      comparator(a, b) { return a.localeCompare(b); },
      strategy: Set.ArrayStrategy
    });
  }

  insert(tokenName) {
    this.tokenSet.insert(tokenName);
    this.emit('change');
  }

  reset(tokenArray) {
    this.tokenSet.clear();
    for (let token of tokenArray) { this.tokenSet.insert(token); } // O(n^2), but should be fast
    this.emit('change');
  }

  contains(tokenName) {
    return this.tokenSet.contains(tokenName);
  }

  remove(tokenName) {
    this.tokenSet.remove(tokenName);
    return this.emit('change');
  }

  toArray() { 
    return this.tokenSet.toArray();
  }
});
