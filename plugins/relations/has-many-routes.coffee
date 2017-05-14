module.exports = ->

  @value 'ThroughRoutes', (inflector) ->
    ->

      primaryKeyType = @to.attributes[@foreignKey]?.type or 'string'
      foreignKeyType = @from.attributes[@primaryKey]?.type or 'string'

      relationId = inflector.singularize(@as) + 'Id'

      link:
        method: 'put'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @through?.modelName or @to?.modelName
            source: 'body'
            required: false
            root: true
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Add a related item by id for #{ @as }."
        accessType: 'WRITE'

      unlink:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Remove the #{ @as } relation to an item by id."
        accessType: 'WRITE'

      exists:
        method: 'head'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Check the existence of #{ @as } relation to an item by id."
        accessType: 'READ'

  @value 'HasManyRoutes', (inflector) ->
    ->
      primaryKeyType = @to.attributes[@foreignKey]?.type or 'string'
      foreignKeyType = @from.attributes[@primaryKey]?.type or 'string'

      relationId = inflector.singularize(@as) + 'Id'

      findById:
        method: 'get'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Find a related item by id for #{ @as }."
        accessType: 'READ'

      destroyById:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Delete a related item by id for #{ @as }."
        accessType: 'WRITE'

      updateById:
        method: 'put'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @to.modelName
            source: 'body'
            root: true
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Update a related item by id for #{ @as }."
        accessType: 'WRITE'

      patchById:
        method: 'patch'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @to.modelName
            source: 'body'
            root: true
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Patch a related item by id for #{ @as }."
        accessType: 'WRITE'

  @alias 'EmbedManyRoutes', 'HasManyRoutes'