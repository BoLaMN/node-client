module.exports = ->

  @factory 'HasMany', (RelationArray) ->

    class HasMany extends RelationArray

      @initialize: (@from, @to, params) ->
        super

        @

      constructor: (@instance) ->
        super

      build: (data = {}) ->
        data[@foreignKey] = @instance[@primaryKey]

        new @to data, @buildOptions()

      findById: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findById fkId, {}, options

        if not @foreignKey
          return cb

        exists = @indexOf fkId

        if exists > -1
          item = @[exists]

          cb null, item

          Promise.resolve item
        else
          options.instance = @instance
          options.name = @as

          query = @query()
          query.where[@to.primaryKey] = fkId

          @to.findOne query, options
            .tap (res) =>
              @push res
            .asCallback cb

      exists: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @exists fkId, {}, options

        @findById(fkId, options)
          .then (data) ->
            not not data
          .asCallback cb

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        fkAndProps = (item) =>
          item[@foreignKey] = @instance[@primaryKey]

        if Array.isArray data
          data.forEach fkAndProps
        else
          fkAndProps data

        options.instance = @instance
        options.name = @as

        @to.create data, options
          .tap (res) =>
            @push res
          .asCallback cb

      query: (query = {}) ->
        query.where ?= {}
        query.where[@foreignKey] = @instance[@primaryKey]
        query

      get: (query, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get query, {}, options

        if typeof query is 'function'
          return @get {}, {}, query

        options.instance = @instance
        options.name = @as

        @to.find @query(query), options
          .tap (res) =>
            @push res
          .asCallback cb

      updateById: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateById data, {}, options

        if typeof data is 'function'
          return @updateById {}, {}, data

        @findById fkId, options
          .then (instance) ->
            instance.updateAttributes data, options
          .asCallback cb

      destroy: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy fkId, {}, options

        @findById fkId, options
          .then (inst) =>
            index = @indexOf inst

            if index > -1
              @splice index, 1

            inst.destroy options
          .asCallback cb

      remotes: ->
        primaryKeyType = @from.attributes[@primaryKey].type
        foreignKeyType = @to.attributes[@foreignKey].type

        "prototype.#{ @as }.findById":
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

        "prototype.#{ @as }.destroyById":
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

        "prototype.#{ @as }.updateById":
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

        if @through or @type is 'referencesMany'

          "prototype.#{ @as }.link":
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

          "prototype.#{ @as }.unlink":
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

          "prototype.#{ @as }.exists":
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
