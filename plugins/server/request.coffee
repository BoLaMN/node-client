'use strict'

module.exports = ->

  @factory 'Request', (Utils) ->

    class Request
      constructor: (@req, @res, @middlewares, @errorHandlers, @handlers) ->

      handle: (@next) ->
        @middleware()

      middleware: ->
        @next = 'main'

        process = (handle, cb) =>
          handle @req, @res, cb

        Utils.each @route.middlewares, process, @after

      main: ->
        @next = 'next'

        process = (handle, cb) =>
          handle @req, @res, cb

        Utils.each @handlers, process, @after

      after: (err) ->
        if err
          return @error err

        @[@next](err)

      error: (err) ->

        process = (handle, cb) =>
          handle err, @req, @res, cb

        Utils.each @errorHandlers, process, @next
