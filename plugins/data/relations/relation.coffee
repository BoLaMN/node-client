{ camelize, pluralize } = require '../utils/inflector'

extend = require '../utils/extend'

Module = require '../module'
buildOptions = require '../utils/build-options'

module.exports = ->

  @factory 'Relation', ->

    class Relation extends Module

      @define: (from, to, params = {}) ->
        class Instance extends @

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
          @as = camelize @from.modelName, true
        else
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

        if not @from.attributes[@from.primaryKey]
          @from.attribute @from.primaryKey, id: true

        if not @to.attributes[@to.primaryKey]
          @to.attribute @to.primaryKey,
            id: true
            type: 'any'

        if not @through and @discriminator
          @from.attribute @discriminator,
            foreignKey: true
            type: 'any'

        type = @idType or @from.attributes[@primaryKey].type

        if @multiple
          @as = pluralize @as

        options =
          foreignKey: true
          type: type or 'any'

        if @belongs
          @to.attribute @foreignKey, options
        else if @polymorphic
          @from.attribute @foreignKey, options

        @

      constructor: (@instance) ->
        super

        for own key, value of @constructor
          @[key] = value

      buildOptions: ->
        buildOptions @instance, @as, @length + 1

      remotes: ->
        primaryKeyType = @from.attributes[@primaryKey].type

        "prototype.#{ @as }.get":
          method: 'get'
          path: "/:#{ @primaryKey }/#{ @as }"
          params:
            "#{ @primaryKey }":
              type: primaryKeyType
              description: "Primary key for #{ @from.modelName }"
              optional: false
              source: 'url'
            filter:
              type: 'object'
              source: 'query'
              optional: true
            options:
              type: 'object'
              source: 'context'
              optional: true
          description: "Queries #{ @as } of #{ @to.modelName }."
          accessType: 'READ'

        "prototype.#{ @as }.create":
          method: 'post'
          path: "/:#{ @primaryKey }/#{ @as }"
          params:
            "#{ @primaryKey }":
              type: primaryKeyType
              description: "Primary key for #{ @from.modelName }"
              optional: false
              source: 'url'
            data:
              type: @to.modelName
              source: 'body'
              optional: true
            options:
              type: 'object'
              source: 'context'
              optional: true
          description: "Creates a new instance in  #{ @as }  of this model."
          accessType: 'WRITE'

        "prototype.#{ @as }.delete":
          method: 'delete'
          path: "/:#{ @primaryKey }/#{ @as }"
          params:
            "#{ @primaryKey }":
              type: primaryKeyType
              description: "Primary key for #{ @from.modelName }"
              optional: false
              source: 'url'
            where:
              type: 'object'
              source: 'query'
              optional: true
            options:
              type: 'object'
              source: 'context'
              optional: true
          description: "Deletes all #{ @as } of this model."
          accessType: 'WRITE'

        "prototype.#{ @as }.count":
          method: 'get'
          path: "/:#{ @primaryKey }/#{ @as }/count"
          params:
            "#{ @primaryKey }":
              type: primaryKeyType
              description: "Primary key for #{ @from.modelName }"
              optional: false
              source: 'url'
            where:
              type: 'object'
              source: 'query'
              optional: true
              description: 'Criteria to match model instances'
            options:
              type: 'object'
              source: 'context'
              optional: true
          description: "Counts #{ @as } of #{ @to.modelName }"
          accessType: 'READ'
