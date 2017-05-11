'use strict'

module.exports = ->

  @factory 'server', (api, bodyParser, connect, settings, cors) ->
    server = connect()

    server.use bodyParser.urlencoded extended: false
    server.use bodyParser.json()
    server.use cors()

    server.use '/api', api.handle
    #api.use cookieParser settings.cookie_secret

    server
