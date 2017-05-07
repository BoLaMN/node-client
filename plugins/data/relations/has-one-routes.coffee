module.exports = ->

  @value 'HasOneRoutes', ->
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
          refresh:
            type: 'boolean'
            source: 'query'
            optional: true
          options:
            type: 'object'
            source: 'context'
            optional: true
        description: "Fetches hasOne relation #{ @as }."
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
          options:
            type: 'object'
            source: 'context'
        description: "Creates a new instance in #{ @as } of this model."
        accessType: 'WRITE'

      "prototype.#{ @as }.update":
        method: 'put'
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
          options:
            type: 'object'
            source: 'context'
        description: "Update #{ @as } of this model."
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
          options:
            type: 'object'
            source: 'context'
        description: "Deletes #{ @as } of this model."
        accessType: 'WRITE'
