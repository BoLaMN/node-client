module.exports = ->

  @factory 'HasOne', (Relation) ->

    class HasOne extends Relation

      @initialize: (@from, @to, params) ->
        super

        @

      constructor: (@instance) ->
        super

      build: (data = {}) ->
        data[@foreignKey] = @instance[@primaryKey]

        new @to data, @buildOptions()

      query: (query) ->
        query ?= where: {}

        where = @instance[@foreignKey]

        if not where
          return false

        query.where[@foreignKey] = where

        if @discriminator
          discriminator = @instance[@discriminator]

          query.where[@discriminator] = discriminator

        query

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        data[@foreignKey] = @instance[@primaryKey]

        options.instance = @instance
        options.name = @as

        query = @query()

        if not query
          cb()
          return Promise.reject()

        @to.findOrCreate query, data, options
          .asCallback cb

      update: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update data, {}, options

        @get(options).then (instance) =>
          delete data[@foreignKey]
          instance.updateAttributes data, options
        .asCallback cb

      destroy: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy {}, options

        @get(options).then (instance) ->
          instance.destroy options
        .asCallback cb

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        if @$loaded
          cb null, @$loaded
          return Promise.resolve @$loaded

        options.instance = @instance
        options.name = @as

        query = @query query

        if not query
          cb()
          return Promise.reject()

        @to.findOne query, options
          .tap (data) =>
            @$property '$loaded', value: data
          .asCallback cb
