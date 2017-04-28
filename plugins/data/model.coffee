Entity = require './entity'
Relation = require './relations'
Events = require './emitter'
Storage = require './storage'
Attribute = require "./attributes"
Cast = require './cast'
Hooks = require './hooks'

module.exports = ->

  @factory 'Model', ->

    class Model extends Entity
      @models: new Storage

      @extend Events::
      @extend Hooks::

      @extend Attribute
      @extend Cast

      @mixin Relation

      @adapter: (adapter) ->
        @property 'dao',
          value: new adapter @
        @

      @configure: (@modelName, attributes) ->
        @primaryKey = 'id'

        @property 'attributes',
          value: new Storage

        @property 'relations',
          value: new Storage

        Object.keys(attributes).forEach (key) =>
          @attribute key, attributes[key]

        @models.$define @modelName, @

        @

      @define: (name, attributes = {}) ->
        class Instance extends @
        Instance.configure name, attributes
        Instance

      isValid: ->
        true

      fire: (event, options, fn = ->) ->
        options.instance = @

        @constructor.fire event, options, fn

      toObject: ->
        obj = {}

        toValue = (v) ->
          v.toDate?() or
          v.toObject?() or
          v

        for own k, v of @ when v?
          obj[k] = toValue v

        obj

      emit: ->
        super
        @constructor.emit arguments...
        true

      constructor: (obj = {}, options = {}) ->
        super

        @$property '$events', value: {}
        @$property '$isNew',
          value: true
          writable: true
        @$property '$options', value: options

        @$property '$path', ->
          arr = [ @$name ]

          if @$parent?.$path
            arr.unshift @$parent.$path

          if @$index isnt undefined
            arr.push (@$index - 1).toString()

          arr.filter((value) -> value).join '.'

        for own name, relation of @constructor.relations
          @$property name, value: new relation @

        for key, value of options when v?
          @$property '$' + key, value: value
