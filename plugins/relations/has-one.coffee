module.exports = ->

  @include './has-one-routes'

  @factory 'HasOne', (Relation) ->

    class HasOne extends Relation

      constructor: ->
        return super

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

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        options.instance = @instance
        options.name = @as

        filter = @filter filter

        if not filter
          cb()
          return Promise.reject()

        @model.findOne filter, options
          .then (data) =>
            @setAttributes data
          .asCallback cb

