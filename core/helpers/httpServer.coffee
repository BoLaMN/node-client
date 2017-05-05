'use strict'

module.exports = ->

  @provider 'httpServer', (connect, path, log) ->
    server = connect()

    configStageConfigurators = []
    runStageConfigurators = []

    configStageConfigurators.push (app) ->
      server.disable('x-powered-by')

      server.set 'host', 'localhost'
      server.set 'port', 8000
      server.set 'views', 'app/views'
      server.set 'static folders', []

      server.enable 'logging'
      server.enable 'json body parser'
      server.enable 'urlencoded body parser'
      server.enable 'cookie parser'
      server.enable 'user agent parser'
      server.enable 'sessions'

    enabled: true

    config: (configurator) ->
      configStageConfigurators.push(configurator)

    run: (configurator) ->
      runStageConfigurators.push(configurator)

    reset: ->
      configStageConfigurators.length = 0
      runStageConfigurators.length = 0

    $get: ->

      applyConfigurators: ->
        configStageConfigurators.forEach (configurator) ->
          configurator(app)

      addMiddleware: ->
        runStageConfigurators.forEach (configurator) ->
          configurator(app)

      get: (name) ->
        server.get name

      enabled: (name) ->
        server.enabled name

      route: (mod, middleware) ->
        server.use mod, middleware

      use: (mod) ->
        server.use mod

      listen: ->
        port = server.get 'port'
        host = server.get 'host'

        server

        .listen port, host, (err) ->
          if not err
            log.log 'HTTP server running on %s:%s', host, port

        .on 'error', (err) ->
          log.error err
          process.exit 1

  .run (httpServer, env, path, express, settings, log, injector) ->

    if not httpServer.enabled
      return

    isDebugEnvironment = env.is('development')

    httpServer.use (req, res, next) ->
      res.locals.DEBUG = isDebugEnvironment

      next()

    if httpServer.enabled('logging')
      httpServer.use(injector.get('httpServerLogger'))

    if httpServer.enabled('json body parser')
      httpServer.use require('body-parser').json()

    if httpServer.enabled('urlencoded body parser')
      httpServer.use require('body-parser').urlencoded
        extended: true

    if httpServer.enabled('cookie parser')
      httpServer.use require 'cookie-parser'

    if httpServer.enabled('user agent parser')
      httpServer.use require('express-useragent').express()

    folders = httpServer.get('static folders') or []

    folders.forEach (staticFolder) ->
      fullPath = path.resolve(settings.cwd, staticFolder)

      log.warn('Using static files serving middleware for path "%s". \n' +
        'To increase performance use specialized servers (i.e. NGINX or APACHE)', fullPath)

      httpServer.use(express.static(fullPath))

    httpServer.applyConfigurators()
    httpServer.addMiddleware()
    httpServer.listen()
