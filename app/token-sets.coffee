FunctionTokenSet = require('./FunctionTokenSet')
TextTokenSet = require('./TextTokenSet')

factories =
  function: (filter) -> new FunctionTokenSet(filter.function, filter.maxNgramSize)
  text: (filter) -> new TextTokenSet(filter.path, filter.maxNgramSize)

for id, filter of require('../lib/Filters')
  module.exports[id] = factories[filter.logic](filter)
