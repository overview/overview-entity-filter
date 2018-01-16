debug = require('debug')('app')
express = require('express')
fs = require('fs')
oboe = require('oboe')
morgan = require('morgan')

TokenBinStream = require('./TokenBinStream')

app = express()
app.use(morgan('short'))

# Parses "geonames,stop.en" -> [ Filters.geonames, Filters["stop.en"] ]
Filters = require('./token-sets')
parseFilterString = (filterString) ->
  for key in (filterString || '').split(',') when Filters.hasOwnProperty(key)
    Filters[key]

# Returns an HTML page with JavaScript.
#
# The JavaScript will GET /generate
app.get '/show', (req, res, next) ->
  fs.readFile './dist/show', (err, bytes) ->
    return next(err) if err

    res
      .status(200)
      .header('Content-Type', 'text/html; charset=utf-8')
      .header('Cache-Control', 'max-age=10')
      .end(bytes)

# Conform to Overview plugin spec
app.get '/metadata', (req, res) ->
  res
    .status(200)
    .header('Access-Control-Allow-Origin', '*')
    .header('Content-Type', 'application/json')
    .header('Cache-Control', 'max-age=10')
    .end('{}')

# Streams a JSON Array that the client can parse incrementally.
#
# Format:
#
#     [
#       { progress: 0.1 },
#       { progress: 0.2 },
#       { progress: 0.3 },
#       ...
#       { progress: 0.99999 },
#       { tokens: [ { name: 'foo', value: 'Foo', nDocuments: 3, frequency: 6 }, ... ] }
#     ]
app.get '/generate', (req, res) ->
  t1 = new Date()

  includeFilters = parseFilterString(req.query.include)
  excludeFilters = parseFilterString(req.query.exclude)

  res.header('Content-Type', 'application/json')
  res.header('Cache-Control', 'private, max-age=0')
  res.write('[{"progress":0}')

  stream = new TokenBinStream
    server: req.query.server
    documentSetId: req.query.documentSetId
    apiToken: req.query.apiToken
    filters:
      include: includeFilters
      exclude: excludeFilters

  stream.on('data', (obj) -> res.write(',' + JSON.stringify(obj)))
  stream.on('error', (err) -> res.write(',' + JSON.stringify(error: err.toString())))
  stream.on('end', -> res.end(']'); console.log("Request duration: #{new Date() - t1}"))

  # Stop streaming when the client goes away
  req.on 'close', ->
    stream.removeAllListeners()
    stream.destroy()

app.use(express.static(__dirname + '/../dist', {
  immutable: true
  index: false
}))

module.exports = app
