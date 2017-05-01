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
      connect: 'connect'

    @include './section'
    @include './middleware'
    @include './api'
    @include './server'
    @include './settings'

    @starter (server, api, settings, MyModel) ->

      server.listen settings.port, settings.host, ->
        console.log ' server listening at: %s', settings.host + ':' + settings.port

