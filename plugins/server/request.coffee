'use strict'

module.exports = ->

  @factory 'Request', (utils) ->
    { defer, values, flatten, wrap } = utils

    class Request
      constructor: (@middlewares, @errorHandlers) ->

      run: (args...) ->
        length = args.length

        (fn) ->
          deferred = defer()

          done = (err, values...) ->
            if err
              return deferred.reject err

            deferred.resolve values

          wrap(fn, done) args...

          deferred.promise

      handle: (@req, @res, next) ->
        fns = flatten values @middlewares
        err = @error.bind @, next

        Promise.eachSeries fns, @run(@req, @res)
          .then null, err

      error: (next, err) ->
        fns = @errorHandlers

        Promise.each fns, @run(err, @req, @res)
          .then next
