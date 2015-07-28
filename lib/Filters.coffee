module.exports =
  geonames:
    id: 'geonames'
    version: 1
    logic: 'text'
    name: 'Geonames'
    descriptionHtml: 'Around 12 million place names, from <a href="http://www.geonames.org/">geonames.org</a>'
    path: 'data/geonames.txt.gz'
    maxNgramSize: 5
    canInclude: true
    canExclude: false

  "stop.en":
    id: 'stop.en'
    version: 1
    logic: 'text'
    name: 'English stop words'
    descriptionHtml: 'Extremely common English words'
    path: 'data/stop.en.txt'
    maxNgramSize: 1
    canInclude: false
    canExclude: true

