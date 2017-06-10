"use strict"

module.exports = ->

  @provider 'env', ->
    settings = @settings = {}

    mode = (process.env.NODE_ENV or 'development').toLowerCase()

    for own key, value of process.env
      value = true if value is 'true'
      value = false if value is 'false'

      @settings[key] = value

    equals = (anotherMode) ->
      mode is anotherMode

    @set = (key, value) ->
      Utils.set settings, key, value 

    @mode = (newMode) ->
      if newMode
        mode = newMode
      else
        mode

    @is = equals

    @load = (definition) ->
      @settings = definition

    @$get = (Utils) ->

      settings.get = (path, value) ->
        Utils.get(settings, path) or value

      settings.has = (path) ->
        not not Utils.get settings, path

      settings.is = equals

      settings