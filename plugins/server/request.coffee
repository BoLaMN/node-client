'use strict'

module.exports = ->

  @factory 'Request', (Utils) ->
    { promisify } = Utils

    class Request
      constructor: (@middlewares, @errorHandlers, @handlers) ->

      run: (fns, args...) ->
        length = args.length

        isPromise = (o = {}) ->
          typeof o.then is "function" or
          typeof o.catch is "function"

        fns.map (fn, i) ->
          new Promise (resolve, reject) ->
            args[length] = (err, values...) ->
              if err
                return reject err

              resolve values

            response = fn.apply null, args

            if isPromise response
              resolve response

      handle: (@req, @res, done) ->
        fns = @middlewares.concat @handlers

        Promise.all @run(fns, @req, @res)
          .catch @error.bind(@)
          .asCallback done

      error: (err) ->
        fns = @errorHandlers

        Promise.all @run(fns, err, @req, @res)
