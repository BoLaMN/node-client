extend = require './utils/extend'

module.exports = ->

  @factory 'Model', (Entity, Attribute, Events, Hooks, Models, Storage, Cast, Relations) ->

    class Model extends Entity
      @extend Events::
      @extend Hooks::

      @extend Attribute
      @extend Cast

      @mixin Relations

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

        Models.$define @modelName, @

        @

      @define: (name, attributes = {}) ->
        class Instance extends @
        Instance.configure name, attributes

        if @primaryKey
          Instance.primaryKey = @primaryKey

        if @attributes
          extend Instance.attributes, @attributes

        if @relations
          Object.keys(@relations).forEach (relation) =>
            args = @relations[relation].$args
            Instance.defineRelation.apply Instance, args

        Instance

      @check: ->
        true

      @parse: (data = {}) ->
        new @ data

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
