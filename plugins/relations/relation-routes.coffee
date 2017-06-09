module.exports = ->

  @value 'RelationRoutes', ->
    (from) ->

      primaryKey = from.primaryKey
      primaryKeyType = from.getIdAttr()?.type or 'string'

      get:
        method: 'get'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.name }"
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
        description: "Queries #{ @as } of #{ @model.name }."
        accessType: 'READ'

      create:
        method: 'post'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          data:
            type: @model.name
            source: 'body'
            root: true
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        description: "Creates a new instance in  #{ @as }  of this model."
        accessType: 'WRITE'

      delete:
        method: 'delete'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.name }"
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
        path: "/:#{ primaryKey }/#{ @as }/count"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.name }"
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
        description: "Counts #{ @as } of #{ @model.name }"
        accessType: 'READ'

      exists:
        method: 'head'
        path: "/:#{ primaryKey }/#{ @as }"
        params:
          "#{ primaryKey }":
            type: primaryKeyType
            description: "Primary key for #{ from.name }"
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
        description: "#{ @as } exists of #{ @model.name }"
        accessType: 'READ'
