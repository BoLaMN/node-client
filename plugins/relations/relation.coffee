module.exports = ->

  @include './relation-routes'

  @factory 'Relation', (Module, inflector, Utils, Models, ObjectProxy) ->
    { camelize, pluralize } = inflector
    { extend, buildOptions, mergeQuery } = Utils

    class Relation extends Module

      @define: (args...) ->
        class Instance extends @

        Instance.property '$type', value: @name
        Instance.initialize args...
        Instance

      @initialize: (from, model, params = {}) ->
        { polymorphic, through } = params

        @model = model

        if @invert
          @foreignKey = camelize @model.modelName + '_id', true
        else
          @foreignKey = camelize from.modelName + '_id', true

        @modelName = @model.modelName
        @as = camelize @model.modelName, true

        if through and not polymorphic
          @keyThrough = camelize @model.modelName + '_id', true

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
          from.attribute @discriminator,
            foreignKey: true
            type: 'any'

        assign = (type) =>
          if @multiple
            @as = pluralize @as

          options =
            foreignKey: true
            type: type or 'any'

          if @belongs
            from.attribute @foreignKey, options
            from.relations.define @as, @
          else
            if @polymorphic
              from.attribute @foreignKey, options

            from.relations.define @as, @

        if @idType
          assign @idType
        else if through
          Models.get through, (@through) =>
            from.getIdAttr (attr) ->
              assign attr.type
        else
          from.getIdAttr (attr) ->
            assign attr.type

        @

      constructor: (instance) ->
        super

        @$property 'instance', { value: instance }, true
        @$property 'from', { value: instance.constructor }, true

        for own key, value of @constructor
          @$property key, { value }, true

        if not @multiple

          if @type is 'belongsTo'
            @[@model.primaryKey] = @instance[@foreignKey]
          else
            @[@foreignKey] = @instance[@model.primaryKey]

          for key, fn of @model::
            @$property key, { value: fn.bind(@) }, true

          return new ObjectProxy @, @model, @as, @instance

      buildOptions: ->
        buildOptions @instance, @as, @length + 1

      applyScope: (instance, filter = {}) ->
        filter.where ?= {}

        if (@type isnt 'belongsTo' or @type is 'hasOne') and typeof @polymorphic is 'object'
          discriminator = @polymorphic.discriminator

          if @polymorphic.invert
            filter.where[discriminator] = @model.modelName
          else
            filter.where[discriminator] = from.modelName

        if typeof @scope is 'function'
          scope = @scope.call @, instance, filter
        else
          scope = @scope

        if typeof scope is 'object'
          mergeQuery filter, scope

        return