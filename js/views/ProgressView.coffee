module.exports = class ProgressView
  constructor: (@$el) ->
    @progress = 0

  render: ->
    @$el.html('''
      <progress max="1"></progress>
      <small>Scanning all documents for entities…</small>
    ''')

    @$progress = @$el.children('progress')

    @

  setProgress: (fraction) ->
    @$progress.attr('value', fraction)
    @$el.toggleClass('done', fraction == 1)
    @
