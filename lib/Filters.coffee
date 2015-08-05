NumberFormat = /^[0-9\.,]*$/

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

  "icij-offshore-leaks-names":
    id: 'icij-offshore-leaks-names'
    version: 1
    logic: 'text'
    name: 'ICIJ Offshore Leaks names'
    descriptionHtml: 'Over 100,000 terms from the <a href="http://offshoreleaks.icij.org/search">ICIJ Offshore Leaks Database</a>, a directory of companies in 10 offshore jurisdictions'
    path: 'data/icij-offshore-leaks-names.txt.gz'
    maxNgramSize: 1
    canInclude: true
    canExclude: false

  "short.1":
    id: 'short.1'
    version: 1
    logic: 'function'
    function: (token) -> token.length <= 1
    maxNgramSize: 1
    name: 'Short (1-character) words'
    descriptionHtml: 'All single-letter words'
    canInclude: false
    canExclude: true

  "short.2":
    id: 'short.2'
    version: 1
    logic: 'function'
    function: (token) -> token.length <= 2
    maxNgramSize: 1
    name: 'Short (2-character) words'
    descriptionHtml: 'All one- or two-letter words'
    canInclude: false
    canExclude: true

  "short.3":
    id: 'short.3'
    version: 1
    logic: 'function'
    function: (token) -> token.length <= 3
    maxNgramSize: 1
    name: 'Short (3-character) words'
    descriptionHtml: 'All one-, two- or three-letter words'
    canInclude: false
    canExclude: true

  'wordnet-words':
    id: 'wordnet-words'
    version: 1
    logic: 'text'
    name: 'WordNet English words'
    descriptionHtml: '(FIXME: nix this data set?) Over 117,000 English words, plus their plurals and conjugations, from <a href="http://wordnet.princeton.edu/">WordNet</a>, supplemented by a list of common <a href="http://www.d.umn.edu/~tpederse/Group01/WordNet/wordnet-stoplist.html">pronouns, prepositions and conjunctions</a>'
    path: 'data/wordnet-words.txt.gz'
    maxNgramSize: 1
    canInclude: false
    canExclude: true

  'googlebooks-words.en':
    id: 'googlebooks-words.en'
    version: 1
    logic: 'text'
    name: 'Google Books English words'
    descriptionHtml: 'The most common 50,000 uncapitalized words in English books, according to <a href="http://storage.googleapis.com/books/ngrams/books/datasetsv2.html">Google Books</a> <small>(<a href="http://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>)</small>'
    path: 'data/googlebooks-words.en.txt.gz'
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
