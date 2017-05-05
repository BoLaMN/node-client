"use strict"

module.exports = ->

  @service 'error', ->
    (options) ->
      err = new Error options.message

      delete options.message

      options.forEach (prop, name) ->
        err[name] = prop

      err
