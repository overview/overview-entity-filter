fs = require('fs')
bf = require('overview-js-bloom-filter')

TokenSet = require('./TokenSet')

# Stores and loads bloom filters, in ../data/*.bloom
#
# (We'll store these files offline and load them at runtime.)
#
# These files store an enormous amount of data in a relatively small amount of
# space. See https://www.jasondavies.com/bloomfilter/
module.exports = class BloomFilterTokenSet extends TokenSet
  constructor: (@bloomFilter, maxNgramSize) ->
    super(maxNgramSize)

  test: (token, start, end) -> @bloomFilter.test(token, start, end)

# Builds bloom filter data and writes it to a file.
#
# Usage:
#
#   tokens = [ 'the', 'quick', 'brown', 'fox' ]
#   BloomFilterTokenSet.writeSync('path/to/set.bloom', 200, 2, tokens)
#
# Arguments:
#
# * path: path of file to write
# * m, k: bloom filter parameters. Calculate here: http://hur.st/bloomfilter
# * tokens: Array of String tokens
BloomFilterTokenSet.writeSync = (path, m, k, tokens) ->
  bloomFilter = new bf.BloomFilter(m, k)
  bloomFilter.add(token) for token in tokens

  fs.writeFileSync(path, bloomFilter.serialize())

# Creates a bloom filter from a filename.
#
# If you choose the wrong k value, the resulting bloom filter won't match the
# right tokens. Make sure it's the same k value as you used in writeSync().
#
# Usage:
#
#   tokenSet = BloomFilterTokenSet.loadSync('path/to/set.bloom', 2, 3)
#   tokenSet.test('foo') # true or false
#   ...
#
# Arguments:
#
# * path: path of file to read. It must have been written by writeSync()
# * k: bloom filter parameter used in writeSync()
BloomFilterTokenSet.loadSync = (path, maxNgramSize) ->
  buf = fs.readFileSync(path)
  bloomFilter = bf.unserialize(buf)

  new BloomFilterTokenSet(bloomFilter, maxNgramSize)

class BloomFilterTokenSet.Factory
  constructor: (@path, @m, @k, @maxNgramSize) ->

  load: -> BloomFilterTokenSet.loadSync(@path, @maxNgramSize)

  writeSync: (tokens) -> BloomFilterTokenSet.writeSync(@path, @m, @k, tokens)
