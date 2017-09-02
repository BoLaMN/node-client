'use strict'

module.exports = ->

  @factory 'Request', (utils, debug) ->
    { values, flatten, wrap } = utils

    class Request
      constructor: (@middlewares, @errorHandlers) ->

      run: (args...) ->
        (fn) ->
          new Promise (resolve, reject) ->
            
            done = (err, values) ->
              if err
                return reject err

              resolve values

            wrap(fn, done) args...

      handle: (@req, @res, next) ->
        fns = flatten values @middlewares
        err = @error.bind @, next

        Promise.eachSeries fns, @run(@req, @res)
          .then null, err

      error: (next, err) ->
        fns = @errorHandlers

        Promise.each fns, @run(err, @req, @res)
