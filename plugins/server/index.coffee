'use strict'

module.exports = (app) ->

  app

  .plugin 'Server',
    version: '0.0.1'
    dependencies:
      Data: true

  .initializer ->

    @alias 'main', 'server'

    @require
      bodyParser: 'body-parser'
      consolidate: 'consolidate'
      cookieParser: 'cookie-parser'
      cors: 'cors'
      url: 'url'
      HttpError: 'http-error'
      express: 'express'

    @include './types'
    @include './section'
    @include './middleware'
    @include './api'
    @include './server'
    @include './settings'

    @starter (server, api, settings) ->
      port = settings.port

      server.listen port, ->
        console.log "Listening on #{port}", api
