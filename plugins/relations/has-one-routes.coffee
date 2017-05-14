module.exports = ->

  @value 'HasOneRoutes', ->
    (from) ->

      primaryKey = from.primaryKey
      primaryKeyType = from.getIdAttr()?.type or 'string'

      foreignKeyType = @model.getIdAttr()?.type or 'string'

      get:
        method: 'get'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.modelName }"
            required: true
            source: 'path'
          refresh:
            type: 'boolean'
            source: 'query'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Fetches hasOne relation #{ @as }."
        accessType: 'READ'

      create:
        method: 'post'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.modelName }"
            required: true
            source: 'path'
          data:
            type: @model.modelName
            source: 'body'
            root: true
          options:
            type: 'object'
            source: 'context'
        description: "Creates a new instance in #{ @as } of this model."
        accessType: 'WRITE'

      update:
        method: 'put'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.modelName }"
            required: true
            source: 'path'
          data:
            type: @model.modelName
            source: 'body'
            root: true
          options:
            type: 'object'
            source: 'context'
        description: "Update #{ @as } of this model."
        accessType: 'WRITE'

      destroy:
        method: 'delete'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.modelName }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
        description: "Deletes #{ @as } of this model."
        accessType: 'WRITE'

  @alias 'EmbedManyRoutes', 'HasOneRoutes'