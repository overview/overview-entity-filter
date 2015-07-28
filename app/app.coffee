debug = require('debug')('app')
express = require('express')
oboe = require('oboe')
morgan = require('morgan')
tokenize = require('overview-js-tokenizer').tokenize
TokenBin = require('overview-js-token-bin')

app = express()

ProgressInterval = 500 # ms between sends
MaxNTokens = 500 # tokens send to client

Filters = require('./token-sets')

# Turn on logging
switch process.env.NODE_ENV
  when 'test' then # do nothing
  when 'development' then app.use(morgan('dev'))
  else app.use(morgan('combined'))

# Parses "geonames,stop.en" -> [ Filters.geonames, Filters["stop.en"] ]
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
  nDocuments = 0
  nDocumentsTotal = 1
  tokenBin = new TokenBin([])

  res.header('Content-Type', 'application/json')
  res.write('[{"progress":0}')

  sendProgress = -> res.write(",{\"progress\":#{nDocuments / nDocumentsTotal}}")
  interval = setInterval(sendProgress, ProgressInterval)

  includeFilters = parseFilterString(req.query.include)
  excludeFilters = parseFilterString(req.query.exclude)

  stream = oboe
    url: "#{req.query.server}/api/v1/document-sets/#{req.query.documentSetId}/documents?fields=text&stream=true"
    headers:
      Authorization: "Basic #{new Buffer("#{req.query.apiToken}:x-auth-token", 'ascii').toString('base64')}"

  stream.node 'pagination.total', (total) ->
    nDocumentsTotal = total
    oboe.drop

  stream.node 'items.*', (doc) ->
    tokens = tokenize(doc.text)
    toAdd = []

    # Tokens aren't unigrams here, so there could be a crazy number of them. We
    # need to filter them before adding to the TokenBin.
    if includeFilters.length
      tokensString = tokens.join(' ')
      for filter in includeFilters
        moreToAdd = filter.findTokensFromUnigrams(tokensString)
        toAdd = toAdd.concat(moreToAdd)
    else
      toAdd = tokens

    for excludeFilter in excludeFilters
      newToAdd = (token for token in toAdd when !excludeFilter.test(token))
      toAdd = newToAdd

    tokenBin.addTokens(toAdd)

    nDocuments++

    oboe.drop

  finishResponse = (json) ->
    if json.error?.thrown?
      # oboe's JSON objects defy stringifying. Clone it without the "thrown"
      e = json.error
      json =
        error:
          thrown: e.thrown.toString()
          statusCode: e.statusCode
          body: e.body
          jsonBody: e.jsonBody
    clearInterval(interval)
    stream.abort() # Prevent further events
    res.write(',')
    res.write(JSON.stringify(json))
    res.end(']')
    interval = undefined
    console.log("Request duration: #{new Date() - t1}")

  stream.done ->
    tokens = tokenBin.getTokensByFrequency().slice(0, MaxNTokens)
    finishResponse(tokens: tokens)

  # Stop streaming when the client goes away
  req.on('close', -> finishResponse(error: 'request aborted'))

  # Stop streaming when the streaming fails
  stream.fail((err) -> finishResponse(error: err))

app.use(express.static('public'))

module.exports = app
