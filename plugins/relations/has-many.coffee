module.exports = ->

  @include './has-many-routes'

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

      find: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @find fkId, {}, options

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

        @find fkId, options
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

      update: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update fkId, data, {}, options

        if typeof data is 'function'
          return @update fkId, {}, {}, data

        @find fkId, options
          .then (instance) ->
            instance.updateAttributes data, options
          .asCallback cb

      patch: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @patch fkId, data, {}, options

        if typeof data is 'function'
          return @patch fkId, {}, {}, data

        query = @query()
        query.where[@to.primaryKey] = fkId

        @to.update query, data, options
          .asCallback cb

      destroy: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy fkId, {}, options

        instance = @build()
        instance.setId fkId

        index = @indexOf instance

        if index > -1
          @splice index, 1

        instance.destroy options
          .asCallback cb
