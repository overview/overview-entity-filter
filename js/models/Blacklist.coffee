events = require('events')
Set = require('js-sorted-set')

# A sorted set of token names.
module.exports = class Blacklist extends events.EventEmitter
  constructor: ->
    super()

    @tokenSet = new Set
      comparator: (a, b) -> a.localeCompare(b)
      strategy: Set.ArrayStrategy

  insert: (tokenName) ->
    @tokenSet.insert(tokenName)
    @emit('change')

  contains: (tokenName) ->
    @tokenSet.contains(tokenName)

  remove: (tokenName) ->
    @tokenSet.remove(tokenName)
    @emit('change')

  toArray: -> 
    @tokenSet.toArray()
