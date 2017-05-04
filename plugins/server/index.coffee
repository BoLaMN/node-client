'use strict'

module.exports = (app) ->

  app

  .module 'Server', []

  .initializer ->

    @require
      bodyParser: 'body-parser'
      url: 'url'
      HttpError: 'http-error'
      connect: 'connect'

    @include './section'
    @include './middleware'
    @include './api'
    @include './server'
    @include './settings'

    @run (server, api, settings, MyModel) ->

      server.listen settings.port, settings.host, ->
        console.log ' server listening at: %s', settings.host + ':' + settings.port

