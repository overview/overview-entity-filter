debug = require('debug')('app')
express = require('express')
oboe = require('oboe')
morgan = require('morgan')

TokenBinStream = require('./TokenBinStream')

app = express()

# Turn on logging
switch process.env.NODE_ENV
  when 'test' then # do nothing
  when 'development' then app.use(morgan('dev'))
  else app.use(morgan('combined'))

# Parses "geonames,stop.en" -> [ Filters.geonames, Filters["stop.en"] ]
Filters = require('./token-sets')
parseFilterString = (filterString) ->
  for key in (filterString || '').split(',') when Filters.hasOwnProperty(key)
    Filters[key]

# Returns an HTML page with JavaScript.
#
# The JavaScript will GET /generate
app.get('/show', (req, res) -> res.render('show.jade'))

# Conform to Overview plugin spec
app.get('/metadata', (req, res) -> res.status(204).header('Access-Control-Allow-Origin', '*').end())

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
#       { tokens: [ { name: 'foo', nDocuments: 3, frequency: 6 }, ... ] }
#     ]
app.get '/generate', (req, res) ->
  t1 = new Date()

  includeFilters = parseFilterString(req.query.include)
  excludeFilters = parseFilterString(req.query.exclude)

  res.header('Content-Type', 'application/json')
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

app.use(express.static('public'))

module.exports = app
