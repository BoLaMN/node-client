module.exports = ->

  @include './relation-routes'

  @factory 'Relation', (Module, inflector, Utils, Models, ObjectProxy) ->
    { camelize, pluralize } = inflector
    { extend, buildOptions, mergeQuery } = Utils

    class Relation extends Module

      @define: (from, to, params = {}) ->
        class Instance extends @

        Instance.property '$type', value: @name
        Instance.initialize from, to, params
        Instance

      @initialize: (from, to, params) ->
        { polymorphic, through } = params

        if @invert
          @primaryKey = @to.primaryKey
          @foreignKey = camelize @to.modelName + '_id', true
        else
          @primaryKey = @from.primaryKey
          @foreignKey = camelize @from.modelName + '_id', true

        if @belongs
          @modelName = @from.modelName
          @as = camelize @from.modelName, true
        else
          @modelName = @to.modelName
          @as = camelize @to.modelName, true

        if through
          @keyThrough = camelize @to.modelName + '_id', true

        if polymorphic?
          @polymorphic = true

          if typeof polymorphic is 'string'
            polymorphic = as: camelize polymorphic, true

          @foreignKey = camelize @as + '_id', true
          @discriminator = camelize @as + '_type', true

          extend params, polymorphic

          delete params.polymorphic

        for own key, val of params
          @[key] = val

        if not @through and @discriminator
          @from.attribute @discriminator,
            foreignKey: true
            type: 'any'

        assign = (type) =>
          if @multiple
            @as = pluralize @as

          options =
            foreignKey: true
            type: type or 'any'

          if @belongs
            @to.attribute @foreignKey, options
            @to.relations.define @as, @
          else
            if @polymorphic
              @from.attribute @foreignKey, options

            @from.relations.define @as, @

        if @idType
          assign @idType
        else if through
          Models.get through, (@through) =>
            @from.attributes.get @primaryKey, (attr) ->
              assign attr.type
        else
          @from.attributes.get @primaryKey, (attr) ->
            assign attr.type

        @

      constructor: (instance) ->
        super

        @$property 'instance', { value: instance }, true

        for own key, value of @constructor
          @$property key, { value }, true

        if not @multiple

          if @type is 'belongsTo'
            @[@primaryKey] = @instance[@foreignKey]
            ctor = @from
          else
            @[@foreignKey] = @instance[@primaryKey]
            ctor = @to

          for key, fn of ctor::
            @$property key, { value: fn.bind(@) }, true

          return new ObjectProxy @, @ctor, @as, @instance

      buildOptions: ->
        buildOptions @instance, @as, @length + 1

      applyScope: (instance, filter = {}) ->
        filter.where ?= {}

        if (@type isnt 'belongsTo' or @type is 'hasOne') and typeof @polymorphic is 'object'
          discriminator = @polymorphic.discriminator

          if @polymorphic.invert
            filter.where[discriminator] = @to.modelName
          else
            filter.where[discriminator] = @from.modelName

        if typeof @scope is 'function'
          scope = @scope.call @, instance, filter
        else
          scope = @scope

        if typeof scope is 'object'
          mergeQuery filter, scope

        return