'use strict'

module.exports = ->

  @run (api, HttpError, AccessHandler, bodyParser, cors) ->

    api.use 'initial', [
      bodyParser.urlencoded extended: false
      bodyParser.json()
      cors()
    ]

    api.use 'auth', AccessHandler.check

    api.error (err, req, res, next) ->
      { code, statusCode } = err
      console.log err
      res.json err, {}, code or statusCode or 500

      return
