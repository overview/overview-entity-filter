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

  "us-surnames":
    id: 'us-surnames'
    version: 1
    logic: 'text'
    name: 'United States surnames'
    descriptionHtml: 'The 150,000 most common surnames in the United States, from <a href="http://www.census.gov/topics/population/genealogy/data/2000_surnames.html">the 2000 census</a>'
    path: 'data/us-surnames.txt.gz'
    maxNgramSize: 1 # weird, eh? And it's all ASCII.
    canInclude: true
    canExclude: false
