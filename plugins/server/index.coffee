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

    @starter (server, api, settings) ->
      port = settings.port

      fn = (params, cb) ->
        console.log params, cb
        cb()

      list = fn
      add = fn
      update = fn
      remove = fn

      api.section "test"
        .get "/", list
        .get "/:id",
          params:
            id: "int"
          , list
        .put "/",
          params:
            description:
              type: "string",
              source: "body"
          , add
        .post "/:id",
          params:
            id: "int"
            done:
              type: "boolean"
              source: "body"
              optional: true
            description:
              type: "string"
              source: "body"
              optional: true
          , update
        .delete "/:id",
          params:
            id: "int"
          , remove

      console.log inspect(JSON.parse(JSON.stringify(api)), false, null)

      server.listen port, ->
        console.log "Listening on #{port}"
