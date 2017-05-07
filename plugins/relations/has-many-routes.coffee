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
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            optional: false
            source: 'url'
          data:
            type: @through.modelName
            source: 'body'
            optional: true
          options:
            type: 'object'
            source: 'context'
            optional: true
        description: "Add a related item by id for #{ @as }."
        accessType: 'WRITE'

      unlink:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            optional: false
            source: 'url'
          options:
            type: 'object'
            source: 'context'
            optional: true
        description: "Remove the #{ @as } relation to an item by id."
        accessType: 'WRITE'

      exists:
        method: 'head'
        path: "/:#{ @primaryKey }/#{ @as }/rel/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: 'any'
            description: "Primary key for #{ @from.modelName }"
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            optional: false
            source: 'url'
          options:
            type: 'object'
            source: 'context'
            optional: true
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
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            optional: false
            source: 'url'
          options:
            type: 'object'
            source: 'context'
            optional: true
        description: "Find a related item by id for #{ @as }."
        accessType: 'READ'

      destroy:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
            optional: false
            source: 'url'
          options:
            type: 'object'
            source: 'context'
            optional: true
        description: "Delete a related item by id for #{ @as }."
        accessType: 'WRITE'

      updateById:
        method: 'put'
        path: "/:#{ @primaryKey }/#{ @as }/:#{ @foreignKey }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            optional: false
            source: 'url'
          "#{ @foreignKey }":
            type: foreignKeyType
            description: "Foreign key for #{ @as }"
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
        description: "Update a related item by id for #{ @as }."
        accessType: 'WRITE'
