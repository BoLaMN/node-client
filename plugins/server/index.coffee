'use strict'

module.exports = (app) ->

  app

  .module 'Server', [ 'Type' ]

  .initializer ->

    @require
      bodyParser: 'body-parser'
      url: 'url'
      HttpError: 'http-error'
      connect: 'connect'
      cors: 'cors'

    @include './section'
    @include './middleware'
    @include './api'
    @include './server'
    @include './swagger'

    @run (server, api, settings) ->

      server.listen settings.port, settings.host, ->
        console.log ' server listening at: %s', settings.host + ':' + settings.port

