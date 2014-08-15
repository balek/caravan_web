gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
sourcemaps = require 'gulp-sourcemaps'
ngAnnotate = require 'gulp-ng-annotate'
jade = require 'gulp-jade'
inject = require 'gulp-inject'
stylus = require 'gulp-stylus'
connect = require 'gulp-connect'
clone = require('node-v8-clone').clone


mainBowerFiles = require 'main-bower-files'
merge = require 'merge-stream'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'



production = false
deps_scripts = gulp.src ''
app_scripts = gulp.src ''

gulp.task 'webserver', ->
    connect.server
        livereload: true
        root: 'dist'
        host: '0.0.0.0'

    require('policyfile').createServer().listen();


gulp.task 'app', appTask = ->
    app_scripts = gulp.src 'src/**/*.coffee'

    if production
        app_scripts
            .pipe do sourcemaps.init
            .pipe do coffee
            .pipe do ngAnnotate
            .pipe concat 'app.js'
            .pipe do uglify
            .pipe sourcemaps.write '.'
            .pipe gulp.dest 'dist'
            .pipe do connect.reload
    else
        app_scripts
            .pipe do coffee
            .pipe gulp.dest 'dist/app'
            .pipe do connect.reload


gulp.task 'deps', depsTask = ->
    autobahnjs =
        browserify 'autobahn',
                standalone: 'autobahn'
            .bundle()
            .pipe source 'autobahn.js'
            .pipe do buffer
    bower_scripts = gulp.src do mainBowerFiles
    deps_scripts = merge autobahnjs, bower_scripts

    if production
        deps_scripts
            .pipe do sourcemaps.init
                .pipe concat 'deps.js'
                .pipe do uglify
            .pipe sourcemaps.write '.'
            .pipe gulp.dest 'dist'
            .pipe do connect.reload
    else
        deps_scripts
            .pipe gulp.dest 'dist/deps'
            .pipe do connect.reload


gulp.task 'scripts', [ 'app', 'deps' ]


gulp.task 'styles', ->
    gulp.src 'src/styles/main.styl'
        .pipe stylus
            include: 'bower_components'
        .pipe gulp.dest 'dist'
        .pipe do connect.reload


gulp.task 'html', ->
    if production
        deps = gulp.src ['deps.js', 'app.js'], read: false, cwd: 'dist'
    else
        deps = mainBowerFiles().map (path) ->
            'deps/' + path.split('/').pop()
        deps.push('deps/autobahn.js')
        deps.push('app/**/*.js')
        deps = gulp.src deps, read: false, cwd: 'dist'

    gulp.src 'src/**/*.jade'
        .pipe inject deps, ignorePath: 'dist', name: 'deps'
        .pipe jade
            pretty: not production
        .pipe gulp.dest 'dist'
        .pipe do connect.reload

gulp.task 'flashpolicy', ->
    gulp.src ['src/flashpolicy.xml', 'src/flashpolicyd.py']
        .pipe gulp.dest 'dist'


gulp.task 'watch', ->
    gulp.watch ['src/**/*.jade', 'dist/**/*.js'], ['html']
    gulp.watch 'src/**/*.coffee', ['app']
    gulp.watch 'src/styles/main.styl', ['styles']


gulp.task 'default', ['scripts', 'styles', 'html', 'flashpolicy', 'watch', 'webserver']
