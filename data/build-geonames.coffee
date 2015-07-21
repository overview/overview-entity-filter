#!/usr/bin/env coffee

# Builds data/geonames.bloom.gz
#
# Usage:
#
# 0. npm install
# 1. cd data
# 2. wget http://download.geonames.org/export/dump/allCountries.zip
# 3. unzip allCountries.zip # -> creates allCountries.txt
# 4. ./build-geonames.coffee

fs = require('fs')
byline = require('byline')
tokenize = require('overview-js-tokenizer').tokenize
tokenSets = require('../app/token-sets')

tokensArr = [] # Array of unique tokens
tokensObj = {} # Hash of token -> null

nRows = 0
nTokens = 0

handleToken = (token) ->
  token = token.toLowerCase()
  if token not of tokensObj
    nTokens++
    tokensObj[token] = null
    tokensArr.push(token)

handleLine = (line) ->
  nRows++
  row = line.split('\t', 4)

  name = row[1]
  alternateNames = row[3]
    .replace(/,(http|https|ftp):[^,]+/g, '') # Remove hrefs
    .replace(/,/g, ' ') # ',' (\u002c) is MidNum in Unicode tr29 and will confuse tokenize()

  handleToken(token) for token in tokenize(name) # "name" column
  handleToken(token) for token in tokenize(alternateNames) # "alternatenames" column
  if nRows % 100000 == 0
    console.log('So far, handled %d tokens in %d rows', nTokens, nRows)

dumpBloomGz = ->
  TokenSet = tokenSets.geonames
  TokenSet.writeBloomGzBufferSync(tokensArr)
  console.log('Dumped geonames.bloom-data.gz, %d tokens', nTokens)

fs.createReadStream(__dirname + '/allCountries.txt', 'utf-8')
  .pipe(new byline.LineStream(encoding: 'utf-8'))
  .on('data', handleLine)
  .on('end', dumpBloomGz)
