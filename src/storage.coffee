Entity = require './entity'

class Storage extends Entity
  constructor: (obj = {}) ->
    super

    for key, value of obj
      @$define key, value

  $get: (names, next) ->

    get = (name, cb) =>
      if @[name]
        return cb @[name]

      @once name, cb

    if typeof next isnt 'function'
      if Array.isArray names
        names.map (name) =>
          @[name]
      else
        @[names]
    else
      @$each names, get, next

  $define: (name, obj) ->
    @[name] = obj

    @emit name, obj

    true

  inspect: ->
    vals = {}

    for own key, value of @
      vals[key] = value

    vals

module.exports = Storage