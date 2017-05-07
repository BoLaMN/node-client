module.exports = ->

  @value 'HasManyThroughRoutes', ->
    ->
      link:
        method: 'put'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @through.modelName
            source: 'body'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Add a related item by id for #{ @as }."
        accessType: 'WRITE'

      unlink:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
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
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
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

  @value 'HasManyRoutes', ->
    ->
      primaryKeyType = @to.attributes[@primaryKey]?.type or 'any'
      foreignKeyType = @from.attributes[@foreignKey]?.type or 'any'

      findById:
        method: 'get'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
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

      destroy:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
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
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @to.modelName
            source: 'body'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Update a related item by id for #{ @as }."
        accessType: 'WRITE'

      patchById:
        method: 'patch'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          "#{ @foreignKey }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @to.modelName
            source: 'body'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Patch a related item by id for #{ @as }."
        accessType: 'WRITE'
