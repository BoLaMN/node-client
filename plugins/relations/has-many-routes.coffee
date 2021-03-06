module.exports = ->

  @value 'ThroughRoutes', (inflector) ->
    (from) ->

      primaryKey = from.primaryKey
      primaryKeyType = from.getIdAttr()?.type or 'string'

      foreignKeyType = @model.getIdAttr()?.type or 'string'

      relationId = inflector.singularize(@as) + 'Id'

      link:
        method: 'put'
        path: "/:#{ primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: 'any'
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: 'any'
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          data:
            type: @through?.name or @model?.name
            source: 'body'
            required: false
            root: true
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: @through?.name or @model?.name
            root: true 
        description: "Add a related item by id for #{ @as }."
        accessType: 'WRITE'

      unlink:
        method: 'delete'
        path: "/:#{ primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: 'any'
            description: "Primary key for #{ from.name }"
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
        returns:
          count:
            type: 'object'
            description: 'The number of instances deleted'
            root: true
        description: "Remove the #{ @as } relation to an item by id."
        accessType: 'WRITE'

      exists:
        method: 'head'
        path: "/:#{ primaryKey }/#{ @as }/rel/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: 'any'
            description: "Primary key for #{ from.name }"
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
        returns: 
          exists:
            type: 'boolean'
        description: "Check the existence of #{ @as } relation to an item by id."
        accessType: 'READ'

  @value 'HasManyRoutes', (inflector) ->
    (from) ->

      primaryKey = from.primaryKey
      primaryKeyType = from.getIdAttr()?.type or 'string'

      foreignKeyType = @model.getIdAttr()?.type or 'string'

      relationId = inflector.singularize(@as) + 'Id'

      findById:
        method: 'get'
        path: "/:#{ primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: foreignKeyType
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: primaryKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: @model?.name
            root: true 
        description: "Find a related item by id for #{ @as }."
        accessType: 'READ'

      destroyById:
        method: 'delete'
        path: "/:#{ primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: foreignKeyType
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: primaryKeyType
            description: "Foreign key for #{ @as }"
            required: true
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          count:
            type: 'object'
            description: 'The number of instances deleted'
            root: true
        description: "Delete a related item by id for #{ @as }."
        accessType: 'WRITE'

      updateById:
        method: 'put'
        path: "/:#{ primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: foreignKeyType
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: primaryKeyType
            description: "Foreign key for #{ @as }"
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
        returns:
          success:
            type: 'boolean'
        description: "Update a related item by id for #{ @as }."
        accessType: 'WRITE'

      patchById:
        method: 'patch'
        path: "/:#{ primaryKey }/#{ @as }/:#{ relationId }"
        params:
          "#{ primaryKey }":
            type: foreignKeyType
            description: "Primary key for #{ from.name }"
            required: true
            source: 'path'
          "#{ relationId }":
            type: primaryKeyType
            description: "Foreign key for #{ @as }"
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
        returns:
          success:
            type: 'boolean'
        description: "Patch a related item by id for #{ @as }."
        accessType: 'WRITE'

  @alias 'EmbedManyRoutes', 'HasManyRoutes'