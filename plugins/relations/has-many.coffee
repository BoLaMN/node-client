module.exports = ->

  @include './has-many-routes'

  @relation 'HasMany', (RelationArray) ->

    class HasMany extends RelationArray

      constructor: ->
        return super

      build: (data = {}) ->
        data[@foreignKey] = @instance.getId()

        new @model data, @buildOptions()

      findById: (fkId, options = {}, cb = ->) ->
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
          filter.where[@model.primaryKey] = fkId

          @model.findOne filter, options
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
          item[@foreignKey] = @instance.getId()

        if Array.isArray data
          data.forEach fkAndProps
        else
          fkAndProps data

        options.instance = @instance
        options.name = @as

        @model.create data, options
          .tap (res) =>
            @push res
          .asCallback cb

      filter: (filter = {}) ->
        filter.where ?= {}
        filter.where[@foreignKey] = @instance.getId()
        filter

      get: (filter, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get filter, {}, options

        if typeof filter is 'function'
          return @get {}, {}, filter

        options.instance = @instance
        options.name = @as

        @model.find @filter(filter), options
          .tap (res) =>
            @push res
          .asCallback cb

      updateById: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update fkId, data, {}, options

        if typeof data is 'function'
          return @update fkId, {}, {}, data

        @find fkId, options
          .then (instance) ->
            instance.updateAttributes data, options
          .asCallback cb

      patchById: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @patch fkId, data, {}, options

        if typeof data is 'function'
          return @patch fkId, {}, {}, data

        filter = @filter()
        filter.where[@model.primaryKey] = fkId

        @model.update filter, data, options
          .asCallback cb

      destroyById: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy fkId, {}, options

        instance = @build()
        instance.setId fkId

        index = @indexOf instance

        if index > -1
          @splice index, 1

        instance.destroy options
          .asCallback cb
