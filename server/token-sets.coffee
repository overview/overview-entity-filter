FunctionTokenSet = require('./FunctionTokenSet')
TextTokenSet = require('./TextTokenSet')
SuffixedCompaniesTokenSet = require('./SuffixedCompaniesTokenSet')

factories =
  function: (filter) -> new FunctionTokenSet(filter.function, filter.maxNgramSize)
  text: (filter) -> new TextTokenSet("#{__dirname}/#{filter.path}", filter.maxNgramSize)
  suffixedCompanies: -> new SuffixedCompaniesTokenSet(filter.maxNgramSize)

for id, filter of require('./Filters')
  module.exports[id] = factories[filter.logic](filter)
