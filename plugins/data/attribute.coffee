module.exports = ->

  @factory 'Attribute', (Storage, Module, Validators, Cast, inflector, Utils) ->
    { camelize } = inflector
    { clone, extend } = Utils

    class Attribute extends Module
      @inherit Cast::

      @attribute: (name, type, options) ->

        exists = @attributes.get name

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

        @attributes.define name, attr

        @

      constructor: (name, options = {}) ->
        super

        for own key, value of options
          @[key] = value

        if Array.isArray @type
          @type = @type.map (f) ->
            f if typeof f is 'string'

        Validators.get @type, (validator) =>
          @validator = validator   
        
        @emit 'define', @, name, options

        @