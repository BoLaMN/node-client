module.exports = ->

  @factory 'Model', (Entity, Attributes, Attribute, Events, Hooks, Models, ModelACL, Inclusion, AccessContext, Storage, Cast, Relations, Utils, ValidationError, Mixin) ->
    { extend, wrap } = Utils

    class Model extends Entity
      @mixin Relations

      @extend Events::
      @extend Hooks::

      @extend ModelACL
      @extend Attribute
      @extend Mixin
      @extend Cast
      @extend Inclusion

      @adapter: (adapter) ->
        @property 'dao',
          value: new adapter @
        @

      @configure: ({ adapter, strict, mixins = {}, properties = {}, relations = {}, acls = [] }) ->
        @primaryKey = 'id'

        @property 'strict',
          value: strict or false

        @property 'acls',
          value: []

        acls.forEach (acl) =>
          @acl acl

        @property 'attributes',
          value: new Attributes

        Object.keys(properties).forEach (key) =>
          @attribute key, properties[key]

        @property 'relations',
          value: new Storage

        Object.keys(relations).forEach (key) =>
          @relation key, relations[key]

        @observe 'validate', (ctx, next) =>
 
          finish = (err) ->
            if err?.length 
              next new ValidationError err
            else next()

          if not @strict 
            return finish()

          @attributes.validate ctx.instance, finish

        Object.keys(mixins).forEach (key) =>
          @mixin key, mixins[key]

        Models.define @name, @

        @

      @define: (name, config) ->
        ctor = @extends name, @
        ctor.configure config

        if @primaryKey
          ctor.primaryKey = @primaryKey

        if @attributes
          extend ctor.attributes, @attributes

        if @relations
          Object.keys(@relations).forEach (relation) =>
            args = @relations[relation].$args
            ctor.relation.apply ctor, args

        ctor

      @check: ->
        true

      @inspect: ->
        @name

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
        if obj instanceof @constructor 
          return obj 
          
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