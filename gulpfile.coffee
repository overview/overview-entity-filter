autoprefixer = require('autoprefixer')
batch = require('gulp-batch')
browserify = require('browserify')
buffer = require('gulp-buffer')
gulp = require('gulp')
gutil = require('gulp-util')
minifyCss = require('gulp-minify-css')
less = require('gulp-less')
plumber = require('gulp-plumber')
postcss = require('gulp-postcss')
source = require('vinyl-source-stream')
sourcemaps = require('gulp-sourcemaps')
watch = require('gulp-watch')
watchify = require('watchify')

gulp.task('default', [ 'css', 'js' ])

gulp.task('watch', [ 'watch-css', 'watch-js' ])

gulp.task 'css', ->
  gulp.src('./css/show.less')
    .pipe(plumber())
    .pipe(sourcemaps.init())
    .pipe(less())
    .pipe(postcss([ autoprefixer(browsers: [ 'last 1 version' ]) ]))
    .pipe(minifyCss(advanced: false))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('public'))

gulp.task 'watch-css', [ 'css' ], ->
  watch 'css/*.(css|less)', batch (evs, cb) ->
    evs.on('end', -> gulp.start('css', cb))

initBrowserify = (options) ->
  b = browserify
    entries: './js/show.coffee'
    extensions: [ '.js', '.coffee' ]
    debug: true
    transform: [ 'coffeeify', 'brfs' ]

  runBundle = ->
    b.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify error'))
      .pipe(source('show.js'))
      .pipe(buffer())
      .pipe(sourcemaps.init(loadMaps: true))
      .pipe(sourcemaps.write('.'))
      .pipe(gulp.dest('./public'))

  if options.watchify
    b = watchify(b)
    b.on('log', gutil.log)
    b.on('update', runBundle)

  # Return the function that runs browserify.
  # gulp.task(initBrowserify(...)) will call this.
  runBundle

gulp.task('js', initBrowserify(watchify: false))

gulp.task('watch-js', initBrowserify(watchify: true))
