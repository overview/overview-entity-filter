BloomFilterTokenSet = require('./BloomFilterTokenSet')
TextTokenSet = require('./TextTokenSet')

module.exports =
  geonames: new TextTokenSet.Factory(
    __dirname + '/../data/geonames.txt.gz',
    5 # The text has 30-grams, but we'll tone that down a little
  )

  #geonames: new BloomFilterTokenSet.Factory(
  #  __dirname + '/../data/geonames.bloom',

  #  # http://hur.st/bloomfilter?n=12148218&p=1e-11
  #  #
  #  # There are n = ~12.1M tokens in the token set.
  #  #
  #  # What should the chance of a false positive be? We want 0 wrong tokens in
  #  # a potential 100M ngrams in a document set, 99.9% of the time.
  #  # p = 0.001 / 100M = 1e-10 ... and make it -11 because hashing is
  #  # imperfect in reality.
  #  640427583,
  #  37,

  #  # The input data has a 30-gram. Let's tone things down a bit.
  #  5
  #)
