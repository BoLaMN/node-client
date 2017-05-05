"use strict"

module.exports = ->

  @provider 'env', (Utils) ->
    config = {}

    mode = (process.env.NODE_ENV or 'development').toLowerCase()

    equals = (anotherMode) ->
      mode is anotherMode

    mode: (newMode) ->
      if newMode
        mode = newMode
      else
        mode

    is: equals

    load: (definition) ->
      config = definition

    set: (path, value) ->
      if not Utils.isString path
        Utils.merge config, path
      else
        Utils.set config, path, value

    $get: ->

      get: (path, defaultVal) ->
        Utils.get(config, path) or value

      has: (path) ->
        not not Utils.get config, path

      is: equals
