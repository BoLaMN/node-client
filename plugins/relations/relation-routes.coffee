module.exports = ->

  @value 'RelationRoutes', ->
    ->
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

      "prototype.#{ @as }.destroy":
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
