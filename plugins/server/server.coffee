'use strict'

module.exports = ->

  @factory 'server', (api, bodyParser, consolidate, cookieParser, cors, express, settings) ->
    server = express()

    server.disable 'x-powered-by'

    server.use cookieParser(settings.cookie_secret)
    server.use bodyParser.urlencoded(extended: false)
    server.use bodyParser.json()
    server.use cors()

    server.use '/api', api.handle

    server
