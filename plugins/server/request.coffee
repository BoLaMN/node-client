'use strict'

module.exports = ->

  @factory 'Request', (utils) ->
    { defer } = utils

    class Request
      constructor: (@middlewares, @errorHandlers, @handlers) ->

      run: (args...) ->
        length = args.length

        isPromise = (o = {}) ->
          typeof o.then is "function" or
          typeof o.catch is "function"

        (fn) ->
          deferred = defer()

          args[length] = (err, values...) ->
            if err
              return deferred.reject err

            deferred.resolve values

          response = fn.apply null, args

          if isPromise response
            return response
          else deferred.promise

      handle: (@req, @res, next) ->
        fns = @middlewares.concat @handlers
        err = @error.bind @, next

        Promise.each fns, @run(@req, @res)
          .then null, err

      error: (next, err) ->
        fns = @errorHandlers

        Promise.each fns, @run(err, @req, @res)
          .then next
