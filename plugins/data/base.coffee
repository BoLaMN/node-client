module.exports = ->

  @factory 'Base', (Entity, Attributes, Attribute, Events, Hooks, Models, ModelACL, Inclusion, AccessContext, Storage, Relations, Utils, ValidationError, Mixin) ->

    class Base extends Entity

      constructor: (data = {}, options = {}) -> 
        if data instanceof @constructor 
          return data 
          
        super

        @$property '$events', value: {}
        @$property '$options', value: options

        @$property '$isNew',
          value: true
          writable: true

        @$property '$path', ->
          arr = [ @$name ]

          if @$parent?.$path
            arr.unshift @$parent.$path

          if @$index isnt undefined
            arr.push @$index.toString()

          arr.filter((value) -> value).join '.'

        for key, value of options when value?
          @$property '$' + key, value: value

        @once '$setup', =>
          for own name, relation of @constructor.relations
            @$property name, value: new relation @

        @on '*', (event, path, value, id) =>
          @$events[event] ?= {}

          if event is '$index'
            @$events[event][path] ?= {}
            @$events[event][path][value] ?= []
            @$events[event][path][value].push id
          else
            @$events[event][path] = value

  , 'model'