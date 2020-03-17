/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const debug = require('debug')('app');
const express = require('express');
const fs = require('fs');
const oboe = require('oboe');
const morgan = require('morgan');

const TokenBinStream = require('./TokenBinStream');

const app = express();
app.use(morgan('short'));

// Parses "geonames,stop.en" -> [ Filters.geonames, Filters["stop.en"] ]
const Filters = require('./token-sets');
const parseFilterString = filterString => (() => {
  const result = [];
  for (let key of Array.from((filterString || '').split(','))) {
    if (Filters.hasOwnProperty(key)) {
      result.push(Filters[key]);
    }
  }
  return result;
})();

// Returns an HTML page with JavaScript.
//
// The JavaScript will GET /generate
app.get('/show', (req, res, next) => fs.readFile('./dist/show', function(err, bytes) {
  if (err) { return next(err); }

  return res
    .status(200)
    .header('Content-Type', 'text/html; charset=utf-8')
    .header('Cache-Control', 'max-age=10')
    .end(bytes);
}));

// Conform to Overview plugin spec
app.get('/metadata', (req, res) => res
  .status(200)
  .header('Access-Control-Allow-Origin', '*')
  .header('Content-Type', 'application/json')
  .header('Cache-Control', 'max-age=10')
  .end('{}'));

// Streams a JSON Array that the client can parse incrementally.
//
// Format:
//
//     [
//       { progress: 0.1 },
//       { progress: 0.2 },
//       { progress: 0.3 },
//       ...
//       { progress: 0.99999 },
//       { tokens: [ { name: 'foo', value: 'Foo', nDocuments: 3, frequency: 6 }, ... ] }
//     ]
app.get('/generate', function(req, res) {
  const t1 = new Date();

  const includeFilters = parseFilterString(req.query.include);
  const excludeFilters = parseFilterString(req.query.exclude);

  res.header('Content-Type', 'application/json');
  res.header('Cache-Control', 'private, max-age=0');
  res.write('[{"progress":0}');

  const stream = new TokenBinStream({
    server: req.query.server,
    documentSetId: req.query.documentSetId,
    apiToken: req.query.apiToken,
    filters: {
      include: includeFilters,
      exclude: excludeFilters
    }
  });

  stream.on('data', obj => res.write(',' + JSON.stringify(obj)));
  stream.on('error', err => res.write(',' + JSON.stringify({error: err.toString()})));
  stream.on('end', function() { res.end(']'); return console.log(`Request duration: ${new Date() - t1}`); });

  // Stop streaming when the client goes away
  return req.on('close', function() {
    stream.removeAllListeners();
    return stream.destroy();
  });
});

app.use(express.static(__dirname + '/../dist', {
  immutable: true,
  index: false
}));

module.exports = app;
