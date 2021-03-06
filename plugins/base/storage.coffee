module.exports = ->

  @factory 'Storage', (Entity, debug) ->

    class Storage extends Entity
      constructor: (obj = {}) ->
        super

        @$property 'keys',
          value: []

        for key, value of obj
          @define key, value

      get: (names, next) ->

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

      define: (name, obj) ->
        if @[name]
          return true

        @keys.push name
        
        @[name] = obj

        if @constructor.debug
          debug @constructor.name + ': ' + name + ' defined ' 

        @emit name, obj

        true

      inspect: ->
        vals = {}

        for own key, value of @
          vals[key] = value

        vals

