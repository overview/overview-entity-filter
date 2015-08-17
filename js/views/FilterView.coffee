$ = require('jquery')
template = require('lodash.template')

Filters = require('../../lib/Filters')

module.exports = class FilterView
  constructor: (@$el, @options) ->
    throw new Error('Must set options.blacklist, a Blacklist') if 'blacklist' not of @options
    throw new Error('Must set options.filters, an Object') if 'filters' not of @options
    throw new Error('Must set options.onSelectFilters, a callback') if 'onSelectFilters' not of @options

    @events.forEach ([ ev, selector, callback ]) =>
      @$el.on(ev, selector, (args...) => @[callback](args...))

    @options.blacklist.on('change', => @_renderBlacklist())

  events: [
    [ 'click', 'button.unblacklist', '_onClickUnblacklist' ]
    [ 'change', 'input', '_onChange' ]
    [ 'submit', 'form', '_onSubmit' ]
  ]

  templates:
    main: template('''
      <form method="post" action="#">
        <div class="include">
          <h3>Search for only these:</h3>
          <ul class="filters"><%= includeFiltersHtml %></ul>
        </div>
        <div class="exclude">
          <h3>… then remove any of these:</h3>
          <ul class="filters"><%= excludeFiltersHtml %></ul>
        </div>
        <div class="blacklist hide">
          <h3>… and omit these, too:</h3>
          <ul class="tokens"></ul>
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

    blacklistItem: template('''
      <li class="token">
        <button class="unblacklist" type="button" title="Un-hide this entity" data-token-name="<%- tokenName %>">❌</button>
        <span class="name"><%- tokenName %></span>
      </li>
    ''')

  # Resets the filters which are selected.
  #
  # This does not emit any signals. Rather, it sets some inputs to checked and
  # sets others to unchecked.
  # unchecks the others.
  setFilters: (filters) ->
    @$el.find('input[type=checkbox]').prop('checked', false)

    for filterId in filters.include
      @$el.find("[name=\"include:#{filterId}\"]").prop('checked', true)
    for filterId in filters.exclude
      @$el.find("[name=\"exclude:#{filterId}\"]").prop('checked', true)

    @_renderSelected()

    @

  render: ->
    allFilters = (f for __, f of Filters).sort((a, b) -> a.name.localeCompare(b.name))

    includeFiltersHtml = (@templates.filter(filter: f, includeOrExclude: 'include') for f in allFilters when f.canInclude).join('')
    excludeFiltersHtml = (@templates.filter(filter: f, includeOrExclude: 'exclude') for f in allFilters when f.canExclude).join('')

    html = @templates.main
      includeFiltersHtml: includeFiltersHtml
      excludeFiltersHtml: excludeFiltersHtml

    @$el.html(html)

    @setFilters(@options.filters)

    @_renderSelected()
    @_renderBlacklist()

    @

  # Sets each li class to "selected" iff it is selected
  _renderSelected: ->
    @$el.find('li').removeClass('selected')
    @$el.find('input:checked').closest('li').addClass('selected')

  # Re-renders the blacklist
  _renderBlacklist: ->
    blacklistHtml = (@templates.blacklistItem(tokenName: t) for t in @options.blacklist.toArray()).join('')

    @$el.find('.blacklist')
      .toggleClass('hide', blacklistHtml.length == 0)
      .find('ul.tokens').html(blacklistHtml)

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

  _onClickUnblacklist: (e) ->
    tokenName = e.currentTarget.getAttribute('data-token-name')
    @options.blacklist.remove(tokenName)
