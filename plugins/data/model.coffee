module.exports = ->

  @factory 'Model', (Entity, Attributes, Attribute, Events, Hooks, Models, ModelACL, Inclusion, AccessContext, Storage, Cast, Relations, Utils, ValidationError) ->
    { extend, wrap } = Utils

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

      @configure: (attributes, acls) ->
        @primaryKey = 'id'

        @property 'acls',
          value: []

        @property 'attributes',
          value: new Attributes

        @property 'relations',
          value: new Storage

        @observe 'validate', (ctx, next) =>

          finish = (err) ->
            if err.length 
              next new ValidationError err
            else next()

          @attributes.validate ctx.instance, finish

        Object.keys(attributes).forEach (key) =>
          @attribute key, attributes[key]

        acls.forEach (acl) =>
          @acl acl

        Models.define @name, @

        @

      @define: (name, attributes = {}, acls = []) ->
        ctor = @extends name, @
        ctor.configure attributes, acls

        if @primaryKey
          ctor.primaryKey = @primaryKey

        if @attributes
          extend ctor.attributes, @attributes

        if @relations
          Object.keys(@relations).forEach (relation) =>
            args = @relations[relation].$args
            ctor.defineRelation.apply ctor, args

        ctor

      @check: ->
        true

      @checkAccess: (id, method, options) ->
        context = new AccessContext
          modelName: @name
          modelId: id
          methodName: method

        context.setToken options.token

        context.checkAccess()

      @swagger:

        schema: (v) ->
          $ref: '#/definitions/' + v.type

        definition: (v) =>
          properties: @attributes

      @getIdAttr: (cb) ->
        @attributes.get @primaryKey, cb

      @parse: (data = {}, options) ->
        new @ data, options

      fire: (event, options, fn = ->) ->
        options.instance = @

        @constructor.fire event, options, fn

      isValid: (errors = [], callback) ->
        if typeof errors is 'function'
          return @isValid {}, errors

        isValid = (v) ->
          v.isValid?(errors) or 
          Promise.resolve()

        promises = [] 

        for own k, v of @ when v?
          promises.push isValid(v).then (err) ->
            errors.push err

        Promise.all(promises).then ->
          error

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
        model = Models.get @constructor.name

        @[model.primaryKey]

      setId: (id) ->
        model = Models.get @constructor.name

        if not id
          delete @[model.primaryKey]
        else
          @[model.primaryKey] = id

        @

  , 'model'