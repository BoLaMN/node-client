module.exports = ->

  @factory 'Model', (Entity, Attribute, Events, Hooks, Models, ModelACL, Inclusion, AccessContext, Storage, Cast, Relations, Utils) ->
    { extend } = Utils

    class Model extends Entity
      @extend Events::
      @extend Hooks::

      @extend ModelACL
      @extend Attribute
      @extend Cast
      @extend Inclusion

      @mixin Relations

      @adapter: (adapter) ->
        @property 'dao',
          value: new adapter @
        @

      @configure: (@modelName, attributes, acls) ->
        @primaryKey = 'id'

        @property 'acls',
          value: []

        @property 'attributes',
          value: new Storage

        @property 'relations',
          value: new Storage

        Object.keys(attributes).forEach (key) =>
          @attribute key, attributes[key]

        acls.forEach (acl) =>
          @acl acl

        Models.define @modelName, @

        @

      @define: (name, attributes = {}, acls = []) ->
        class Instance extends @

        if name
          Instance.configure name, attributes, acls

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

      @checkAccess: (id, method, options) ->
        context = new AccessContext
          modelName: @modelName
          modelId: id
          methodName: method

        context.setToken options.token

        context.checkAccess()

      @swagger:

        schema: (v) ->
          $ref: '#/definitions/' + v.type

        definition: (v) =>
          properties: @attributes

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
        @$property '$options', value: options

        @$property '$isNew',
          value: true
          writable: true

        @$property '$path', ->
          arr = [ @$name ]

          if @$parent?.$path
            arr.unshift @$parent.$path

          if @$index isnt undefined
            arr.push (@$index - 1).toString()

          arr.filter((value) -> value).join '.'

        for key, value of options when v?
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

      checkAccess: (method) ->
        @constructor.checkAccess @getId(), method, @$options

      getId: ->
        @[@constructor.primaryKey]

      setId: (id) ->
        if not id
          delete @[@constructor.primaryKey]
        else
          @[@constructor.primaryKey] = id

        @
