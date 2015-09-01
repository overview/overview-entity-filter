FunctionTokenSet = require('./FunctionTokenSet')
TextTokenSet = require('./TextTokenSet')
SuffixedCompaniesTokenSet = require('./SuffixedCompaniesTokenSet')

factories =
  function: (filter) -> new FunctionTokenSet(filter.function, filter.maxNgramSize)
  text: (filter) -> new TextTokenSet(filter.path, filter.maxNgramSize)
  suffixedCompanies: -> new SuffixedCompaniesTokenSet(filter.maxNgramSize)

for id, filter of require('../lib/Filters')
  module.exports[id] = factories[filter.logic](filter)
