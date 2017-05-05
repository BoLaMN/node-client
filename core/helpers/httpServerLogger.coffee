'use strict'

module.exports = ->

  @provider 'httpServerLogger', (log) ->
    format = '<%= method %> <%= url %> | <%= status %> | <%= length %> kb | <%= elapsed %>ms'

    setFormat: (newFormat) ->
      format = newFormat

    $get: ->
      format = template format

      (req, res, next) ->
        startTime = Date.now()
        socket = res.socket

        if not socket
          return next()

        res.on 'finish', ->
          endTime = Date.now()

          written = Math.round (socket.bytesWritten - (socket.$bytesWritten or 0)) / 1024, 2

          params =
            url: req.originalUrl
            method: req.method
            status: res.statusCode
            elapsed: endTime - startTime
            length: written

          socket.$bytesWritten = socket.bytesWritten

          log.log format params

        next()
