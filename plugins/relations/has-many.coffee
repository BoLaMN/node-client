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
          return @updateById fkId, data, {}, options

        if typeof data is 'function'
          return @updateById fkId, {}, {}, data

        @findById fkId, options
          .then (instance) ->
            instance.updateAttributes data, options
          .asCallback cb

      patchById: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @patchById fkId, data, {}, options

        if typeof data is 'function'
          return @patchById fkId, {}, {}, data

        query = @query()
        query.where[@to.primaryKey] = fkId

        @to.update query, data, options
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
