module.exports = ->

  @include './has-many-routes'

  @factory 'HasMany', (RelationArray) ->

    class HasMany extends RelationArray

      @initialize: (@from, @to, params) ->
        super

        @

      constructor: ->
        return super

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

          filter = @filter()
          filter.where[@to.primaryKey] = fkId

          @to.findOne filter, options
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

      filter: (filter = {}) ->
        filter.where ?= {}
        filter.where[@foreignKey] = @instance[@primaryKey]
        filter

      get: (filter, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get filter, {}, options

        if typeof filter is 'function'
          return @get {}, {}, filter

        options.instance = @instance
        options.name = @as

        @to.find @filter(filter), options
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

        filter = @filter()
        filter.where[@to.primaryKey] = fkId

        @to.update filter, data, options
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
