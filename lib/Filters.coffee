NumberFormat = /^[0-9\.,]*$/

module.exports =
  'geonames.political':
    id: 'geonames.political'
    version: 1
    logic: 'text'
    name: 'Geonames: Political Boundaries'
    descriptionHtml: 'About 300,000 political regions worldwide, such as countries or administrative ares, from <a href="http://www.geonames.org/">geonames.org</a>'
    path: 'data/geonames-political.txt.gz'
    maxNgramSize: 5
    canInclude: true
    canExclude: false
    # To find maxNgramSize:
    # zcat geonames-political.txt.gz | tr -d -c ' \n' | awk '{ if (length > max) max = length } END { print max + 1 }'

  'geonames.cities':
    id: 'geonames.cities'
    version: 1
    logic: 'text'
    name: 'Geonames: Cities'
    descriptionHtml: 'Any city with population over 10,000, plus alternate names, from <a href="http://www.geonames.org/">geonames.org</a>'
    path: 'data/geonames-cities.txt.gz'
    maxNgramSize: 5
    canInclude: true
    canExclude: false

  'stop.en':
    id: 'stop.en'
    version: 1
    logic: 'text'
    name: 'English: stop words'
    descriptionHtml: 'Extremely common English words'
    path: 'data/stop.en.txt'
    maxNgramSize: 1
    canInclude: false
    canExclude: true

  'short.3':
    id: 'short.3'
    version: 1
    logic: 'function'
    function: (token) -> token.length <= 3
    maxNgramSize: 1
    name: 'Short words'
    descriptionHtml: 'All one-, two- or three-letter words'
    canInclude: false
    canExclude: true

  'googlebooks-words.eng':
    id: 'googlebooks-words.eng'
    version: 1
    logic: 'text'
    name: 'English: Google Books words'
    descriptionHtml: 'The most common 50,000 uncapitalized words in English books, according to <a href="http://storage.googleapis.com/books/ngrams/books/datasetsv2.html">Google Books</a> <small>(<a href="http://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>)</small>'
    path: 'data/googlebooks-words.eng.txt.gz'
    maxNgramSize: 1
    canInclude: false
    canExclude: true

  'googlebooks-words.rus':
    id: 'googlebooks-words.rus'
    version: 1
    logic: 'text'
    name: 'Russian: Google Books words'
    descriptionHtml: 'The most common 50,000 uncapitalized words in Russian books, according to <a href="http://storage.googleapis.com/books/ngrams/books/datasetsv2.html">Google Books</a> <small>(<a href="http://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>)</small>'
    path: 'data/googlebooks-words.rus.txt.gz'
    maxNgramSize: 1
    canInclude: false
    canExclude: true

  'numbers':
    id: 'numbers'
    version: 1
    logic: 'function'
    function: (token) -> NumberFormat.test(token)
    maxNgramSize: 1
    name: 'Numbers'
    descriptionHtml: 'Any word composed solely of digits, commas and periods'
    canInclude: true
    canExclude: true
