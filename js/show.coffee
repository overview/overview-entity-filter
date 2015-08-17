$ = require('jquery')
queryString = require('query-string')

App = require('./App')

$ ->
  options = queryString.parse(location.search)
  app = new App($('#main'), options)
    .render()
    .start()
