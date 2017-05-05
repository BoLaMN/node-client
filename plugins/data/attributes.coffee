extend = require './utils/extend'
clone = require './utils/clone'

module.exports = ->

  @factory 'Attribute', (Storage, Module, Cast, inflector) ->
    { camelize } = inflector

    class Attribute extends Module
      @include Cast::

      @attribute: (name, type, options) ->
        @attributes ?= new Storage

        exists = @attributes.$get name

        if exists
          return @

        switch @type type
          when 'string', 'array'
            options ?= {}
            options.type = type
          when 'undefined', 'null'
            options = type: 'any'
          when 'object'
            options = type
          when 'function'
            options =
              fn: type
              type: type.name

        if options.id
          @primaryKey = name

        attr = new Attribute name, options

        @attributes.$define name, attr

        @

      constructor: (name, options = {}) ->
        super

        for own key, value of options
          @[key] = value

        if Array.isArray @type
          @type = @type.map (f) ->
            camelize f if typeof f is 'string'
        else if @type
          @type = camelize @type

        @emit 'define', @, name, options

        @
