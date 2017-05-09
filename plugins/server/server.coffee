'use strict'

module.exports = ->

  @factory 'server', (api, bodyParser, connect, accessHandler, settings, cors) ->
    server = connect()

    server.use '/api', api.handle

    api.use bodyParser.urlencoded extended: false
    api.use bodyParser.json()
    api.use accessHandler

    #api.use cookieParser settings.cookie_secret
    api.use cors()

    server
