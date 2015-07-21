BloomFilterTokenSet = require('./BloomFilterTokenSet')

module.exports =
  geonames: new BloomFilterTokenSet(
    # http://hur.st/bloomfilter?n=5600000&p=0.00005
    #
    # There are ~5.6M tokens in the token set. n = 5700000
    #
    # What should the chance of a false positive be? We want 0 wrong tokens in
    # the list of 200 top tokens, 99% of the time. p = .01/200 = .00005
    # p=.01/100
    'geonames',
    115431747,
    14
  )
