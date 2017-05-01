'use strict'

module.exports = ->

  @factory 'server', (api, bodyParser, consolidate, cookieParser, cors, connect, settings) ->
    server = connect()

    server.use '/api', api.handle

    api.use cookieParser settings.cookie_secret
    api.use bodyParser.urlencoded extended: false
    api.use bodyParser.json()
    api.use cors()

    server
