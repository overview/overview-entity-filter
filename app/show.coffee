require('./show.less') # compile styles

$ = require('jquery')
App = require('./App')

searchParams = (new URL(document.location)).searchParams
options =
  server: searchParams.get('server')
  origin: searchParams.get('origin')
  documentSetId: searchParams.get('documentSetId')
  apiToken: searchParams.get('apiToken')

app = new App($('#main'), options)
  .render()
  .start()
