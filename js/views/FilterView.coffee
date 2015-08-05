$ = require('jquery')
template = require('lodash.template')

Filters = require('../../lib/Filters')

module.exports = class FilterView
  constructor: (@$el, @options) ->
    throw new Error('Must set options.filters, an Object') if 'filters' not of @options
    throw new Error('Must set options.onSelectFilters, a callback') if 'onSelectFilters' not of @options

    @events.forEach ([ ev, selector, callback ]) =>
      @$el.on(ev, selector, (args...) => @[callback](args...))

  events: [
    [ 'click', 'input', '_onChange' ]
    [ 'change', 'input', '_onChange' ]
    [ 'submit', 'form', '_onSubmit' ]
  ]

  templates:
    main: template('''
      <form method="post" action="#">
        <div class="include">
          <h3>Search for only these:</h3>
          <ul><%= includeFiltersHtml %></ul>
        </div>
        <div class="exclude">
          <h3>… then remove any of these:</h3>
          <ul><%= excludeFiltersHtml %></ul>
        </div>
      </form>
    ''')

    filter: template('''
      <li class="filter" data-filter-id="<%- filter.id %>">
        <label>
          <input type="checkbox" name="<%- includeOrExclude %>:<%- filter.id %>" >
          <strong><%- filter.name %></strong>
          <span class="description"><%= filter.descriptionHtml %></span>
        </label>
      </li>
    ''')

  render: ->
    allFilters = (f for __, f of Filters).sort((a, b) -> a.name.localeCompare(b.name))

    includeFiltersHtml = (@templates.filter(filter: f, includeOrExclude: 'include') for f in allFilters when f.canInclude).join('')
    excludeFiltersHtml = (@templates.filter(filter: f, includeOrExclude: 'exclude') for f in allFilters when f.canExclude).join('')

    html = @templates.main
      includeFiltersHtml: includeFiltersHtml
      excludeFiltersHtml: excludeFiltersHtml

    @$el.html(html)

    for filterId in @options.filters.include
      @$el.find("[name=\"include:#{filterId}\"]").prop('checked', true)
    for filterId in @options.filters.exclude
      @$el.find("[name=\"exclude:#{filterId}\"]").prop('checked', true)

    @_renderSelected()

    @

  # Sets each li class to "selected" iff it is selected
  _renderSelected: ->
    @$el.find('li').removeClass('selected')
    @$el.find('input:checked').closest('li').addClass('selected')

  _callSetter: ->
    filters =
      include: []
      exclude: []

    for value in @$el.find('form').serializeArray()
      m = /(include|exclude):(.*)/.exec(value.name)
      filters[m[1]].push(m[2])

    @options.onSelectFilters(filters)

  _onSubmit: (e) ->
    e.preventDefault()
    @_callSetter()

  # If complementName is "include:geonames", uncheck "exclude:geonames"
  _ensureUnchecked: (complementName) ->
    reverse =
      include: 'exclude'
      exclude: 'include'
    m = /(include|exclude):(.*)/.exec(complementName)

    name = "#{reverse[m[1]]}:#{m[2]}"
    @$el.find("input[name=\"#{name}\"]").prop('checked', false)

  _onChange: (e) ->
    name = e.currentTarget.getAttribute('name')
    @_ensureUnchecked(name)
    @_renderSelected()
    @_callSetter()
