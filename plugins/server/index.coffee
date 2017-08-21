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

    @run (server, config) ->

      server.listen config.port, config.host, ->
        console.log ' server listening at: %s', config.host + ':' + config.port

