const FunctionTokenSet = require('./FunctionTokenSet');
const TextTokenSet = require('./TextTokenSet');
const SuffixedCompaniesTokenSet = require('./SuffixedCompaniesTokenSet');

const factories = {
  function(filter) { return new FunctionTokenSet(filter.function, filter.maxNgramSize); },
  text(filter) { return new TextTokenSet(`${__dirname}/${filter.path}`, filter.maxNgramSize); },
  suffixedCompanies() { return new SuffixedCompaniesTokenSet(filter.maxNgramSize); }
};

const object = require('./Filters');
for (let id in object) {
  var filter = object[id];
  module.exports[id] = factories[filter.logic](filter);
}
