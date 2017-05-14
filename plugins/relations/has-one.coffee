module.exports = ->

  @include './has-one-routes'

  @factory 'HasOne', (Relation) ->

    class HasOne extends Relation

      @initialize: (@from, @to, params) ->
        super

        @

      constructor: ->
        return super

      build: (data = {}) ->
        data[@foreignKey] = @instance[@primaryKey]

        new @to data, @buildOptions()

      filter: (filter) ->
        filter ?= where: {}

        where = @instance[@foreignKey]

        if not where
          return false

        filter.where[@foreignKey] = where

        if @discriminator
          discriminator = @instance[@discriminator]

          filter.where[@discriminator] = discriminator

        filter

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        data[@foreignKey] = @instance[@primaryKey]

        options.instance = @instance
        options.name = @as

        filter = @filter()

        if not filter
          cb()
          return Promise.reject()

        @to.findOrCreate filter, data, options
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

        filter = @filter filter

        if not filter
          cb()
          return Promise.reject()

        @to.findOne filter, options
          .tap (data) =>
            @$property '$loaded', value: data
          .asCallback cb

