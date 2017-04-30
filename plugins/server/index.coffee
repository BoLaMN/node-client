'use strict'

{ inspect } = require 'util'

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

    @include './section'
    @include './middleware'
    @include './api'
    @include './server'
    @include './settings'

    @starter (server, api, settings, MyModel) ->
      port = settings.port

      console.log MyModel
      console.log inspect(api.toObject(), false, null)

      server.listen port, ->
        console.log "Listening on #{port}"
