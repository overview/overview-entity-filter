module.exports = class FilterView
  constructor: (@$el) ->
    @filters = []

  render: ->
    @$el.html('Filters go here')
    @
