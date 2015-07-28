#!/usr/bin/env coffee

# Builds geonames.bloom
#
# Usage:
#
# 0. npm install
# 1. cd data
# 2. wget http://download.geonames.org/export/dump/allCountries.zip
# 3. ./build-geonames.txt.sh # creates geonames.txt
# 4. ./build-geonames.bloom.coffee # creates geonames.bloom using geonames.txt

fs = require('fs')
TokenSets = require('../app/token-sets')

tokens = fs.readFileSync(__dirname + '/geonames.txt', 'utf-8').split('\n')

TokenSets.geonames.writeSync(tokens)
