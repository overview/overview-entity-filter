fs = require('fs')
zlib = require('zlib')
BloomFilter = require('bloomfilter').BloomFilter

# Stores and loads bloom filters, in ../data/*.bloom.gz
#
# (We'll store these files offline and load them at runtime.)
#
# A bloom filter stores a lot of data in a tiny amount of space. It has two
# operations:
#
# * add(token): adds a token to the set.
# * test(token): returns true if the token was added, else *probably* false
#
# The "probably" gives enormous space savings. For instance, with p=0.0005
# chance of false positives, a 
module.exports = class BloomFilterTokenSet
  constructor: (@basename, @m, @k) ->

  path: -> "#{__dirname}/../data/#{@basename}.bloom.gz"

  # Returns a set that tests for inclusion
  #
  # Usage:
  #
  #   config = new BloomFilterTokenSet('my-set', 10000, 10)
  #   buf = fs.readFileSync(config.path())
  #   tokenSet = config.load(buf)
  #
  #   tokenSet.test('foo') # true or false
  #   tokenSet.test('bar') # true or false
  #   ...
  load: (gzippedData) ->
    data = zlib.gunzipSync(gzippedData)

    buckets = new Int32Array(data.length / 4)
    for i in [ 0 ... data.length / 4 ]
      buckets[i] = data.readInt32BE(i * 4, true)

    new BloomFilter(buckets, @k)

  # Calls `load()` on the contents of `path()`.
  #
  # Usage:
  #
  #   config = new BloomFilterTokenSet('my-set', 10000, 10)
  #   tokenSet = config.readSync()
  #   tokenSet.test('foo') # true or false
  #   tokenSet.test('bar') # true or false
  readSync: ->
    buf = fs.readFileSync(@path())
    @load(buf)

  # Helps build a .bloom.gz file.
  #
  # Usage:
  #
  #   config = new BloomFilterTokenSet('my-set', 100000, 10)
  #   buf = config.buildBloomGzBuffer(aHugeArrayOfTokens)
  #   fs.writeFileSync(config.path(), buf)
  buildBloomGzBuffer: (tokens) ->
    bloomFilter = new BloomFilter(@m, @k)
    bloomFilter.add(token) for token in tokens
    data = bloomFilter.buckets # an Int32Array of data
    buf = new Buffer(data.length * 4)
    buf.writeInt32BE(int, i * 4, true) for int, i in bloomFilter.buckets
    zlib.gzipSync(buf)

  # Calls `buildBloomGzBuffer()` and then writes to `path()`, synchronously.
  writeBloomGzBufferSync: (tokens) ->
    buf = @buildBloomGzBuffer(tokens)
    fs.writeFileSync(@path(), buf)
