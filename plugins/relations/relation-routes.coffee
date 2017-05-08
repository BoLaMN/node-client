module.exports = ->

  @value 'RelationRoutes', ->
    ->
      primaryKeyType = @from.attributes[@primaryKey].type or 'string'

      get:
        method: 'get'
        path: "/:#{ @primaryKey }/#{ @as }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          filter:
            type: 'object'
            source: 'query'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Queries #{ @as } of #{ @to.modelName }."
        accessType: 'READ'

      create:
        method: 'post'
        path: "/:#{ @primaryKey }/#{ @as }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
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
        description: "Creates a new instance in  #{ @as }  of this model."
        accessType: 'WRITE'

      destroy:
        method: 'delete'
        path: "/:#{ @primaryKey }/#{ @as }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          where:
            type: 'object'
            source: 'query'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Deletes all #{ @as } of this model."
        accessType: 'WRITE'

      count:
        method: 'get'
        path: "/:#{ @primaryKey }/#{ @as }/count"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          where:
            type: 'object'
            source: 'query'
            required: false
            description: 'Criteria to match model instances'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Counts #{ @as } of #{ @to.modelName }"
        accessType: 'READ'

      exists:
        method: 'head'
        path: "/:#{ @primaryKey }/#{ @as }"
        params:
          "#{ @primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ @from.modelName }"
            required: true
            source: 'path'
          where:
            type: 'object'
            source: 'query'
            required: false
            description: 'Criteria to match model instances'
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "#{ @as } exists of #{ @to.modelName }"
        accessType: 'READ'
