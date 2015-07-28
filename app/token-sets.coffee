TextTokenSet = require('./TextTokenSet')

factories =
  text: (filter) -> new TextTokenSet(filter.path, filter.maxNgramSize)

for id, filter of require('../lib/Filters')
  module.exports[id] = factories[filter.logic](filter)
