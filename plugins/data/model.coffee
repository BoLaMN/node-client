module.exports = ->

  @factory 'Model', (Base, ObjectProxy, Attributes, ModelAttribute, Events, ModelHooks, Models, ModelACL, ModelInclusion, AccessContext, Storage, ModelRelations, utils, ValidationError, ModelMixin, debug, merge) ->
    { wrap } = utils

    class Model extends Base
      @mixes ModelRelations

      @extend Events::
      @extend ModelHooks::

      @extend ModelACL
      @extend ModelAttribute
      @extend ModelMixin
      @extend ModelInclusion

      @connector: (connector) ->
        @property 'dao',
          value: new connector @
        @

      @configure: (config) ->
        { 
          acls = [] 
          mixins = {}
          properties = {}
          relations = {}
          strict
        } = config

        @property 'config',
          value: config 

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
          debug 'observe validate', ctx 

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

      @define: (name, config = {}) ->

        if @config?
          config = merge config, @config

        ctor = @extends name, @
        ctor.configure config

        if @primaryKey
          ctor.primaryKey = @primaryKey

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
      
      #@inspect: ->
      #  @name 
        
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

      constructor: (data = {}, options = {}) ->      
        super

        proxy = new ObjectProxy @, @constructor, @$path, @

        @setAttributes data, proxy

        return proxy

      setAttributes: (data = {}, proxy = @) ->
        if data.id and @constructor.primaryKey isnt 'id'
          @setId data.id
          delete data.id

        if data._id
          @setId data._id
          delete data._id

        for own key, value of data when key?
          if typeof proxy[key] is 'function'
            continue if typeof value is 'function'
            proxy[key](value)
          else
            proxy[key] = value

        if not @$loaded
          @emit '$setup', @$path, @

          if @$parent and @$path
            @$parent.emit '$loaded', @$path, @

          @$property '$loaded', { value: true }

        @
        
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