$ = require('jquery')
template = require('lodash.template')

Filters = require('../../lib/Filters')

module.exports = class FilterView
  constructor: (@$el, @options) ->
    throw new Error('Must pass options.include, an Array of filter codes') if 'include' not of @options
    throw new Error('Must pass options.exclude, an Array of filter codes') if 'exclude' not of @options
    throw new Error('Must set options.onSetInclude, a callback') if 'onSetInclude' not of @options
    throw new Error('Must set options.onSetExclude, a callback') if 'onSetExclude' not of @options

    @events.forEach ([ ev, selector, callback ]) =>
      @$el.on(ev, selector, (args...) => @[callback](args...))

  events: [
    [ 'submit', '.include form', '_onSubmitInclude' ]
    [ 'submit', '.exclude form', '_onSubmitExclude' ]
  ]

  templates:
    main: template('''
      <div class="include">
        <p>Only include these:</p>
        <ul>
          <%= includeListHtml %>
          <li><%= includeFormHtml %></li>
        </ul>
      </div>
      <div class="exclude">
        <p>...and filter out any of these:</p>
        <ul>
          <%= excludeListHtml %>
          <li><%= excludeFormHtml %></li>
        <ul>
        </ul>
      </div>
    ''')

    form: template('''
      <form method="post" action="#">
        <select name="filter">
          <option value="">Choose a set of words…</option>
          <% filters.forEach(function(filter) { %>
            <option value="<%- filter.id %>"><%- filter.name %></option>
          <% }); %>
        </select>
        <button type="submit">Add</button>
        <p class="filter-description empty"></p>
      </form>
    ''')

    filters: template('''
      <% filters.forEach(function(filter) { %>
        <li data-filter-id="<%- filter.id %>">
          <h4><%- filter.name %></h4>
          <p class="description"><%= filter.descriptionHtml %></p>
        </li>
      <% }); %>
    ''')

  render: ->
    allFilters = (f for __, f of Filters).sort((a, b) -> a.name.localeCompare(b.name))

    usedFilters = {}
    (usedFilters[filterId] = null) for filterId in @options.include.concat(@options.exclude)

    includeListHtml = @templates.filters(filters: allFilters.filter((f) => f.id in @options.include))
    excludeListHtml = @templates.filters(filters: allFilters.filter((f) => f.id in @options.exclude))
    includeFormHtml = @templates.form(filters: allFilters.filter((f) -> f.id not of usedFilters))
    excludeFormHtml = @templates.form(filters: allFilters.filter((f) -> f.id not of usedFilters))

    html = @templates.main
      includeListHtml: includeListHtml
      excludeListHtml: excludeListHtml
      includeFormHtml: includeFormHtml
      excludeFormHtml: excludeFormHtml
    @$el.html(html)
    @

  _onSubmit: (e, key, setter) ->
    e.preventDefault()
    $form = $(e.currentTarget)
    filterCode = $form.find('select[name=filter]').val()
    return if !filterCode
    currentList = @options[key]
    nextList = currentList.slice()
    nextList.push(filterCode)
    setter(nextList)
    @options[key] = nextList
    @render()

  _onSubmitInclude: (e) -> @_onSubmit(e, 'include', @options.onSetInclude)
  _onSubmitExclude: (e) -> @_onSubmit(e, 'exclude', @options.onSetExclude)
