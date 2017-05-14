module.exports = ->

  @factory 'ReferencesMany', (RelationArray) ->

    class ReferencesMany extends RelationArray
      @embedded: true

      constructor: ->
        return super

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        options.instance = @instance
        options.name = @as

        @model.findByIds @, options
          .asCallback cb

      find: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @find fkId, {}, cb

        id = @instance[@foreignKey] or []

        options.instance = @instance
        options.name = @as

        @model.findById fkId, options
          .asCallback cb

      exists: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @exists fkId, {}, options

        exists = @indexOf fkId

        if exists > -1
          item = @[exists]

        cb null, item

        item

      update: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update data, {}, options

        if typeof data is 'function'
          return @update {}, {}, data

        @find fkId, options
          .then (instance) ->
            instance.updateAttributes data, options
          .asCallback cb

      destroy: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy fkId, {}, options

        @find fkId, options
          .then (instance) =>
            Promise.all [
              @remove instance
              instance.destroy
            ]
          .asCallback cb

      at: (index, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @at index, {}, options

        ids = @instance[@foreignKey] or []

        @find ids[index], options
          .asCallback cb

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        inst = @build data

        options.instance = @instance
        options.name = @as

        inst.save options
          .then => @insert inst
          .asCallback cb

      build: (data = {}) ->
        new @model data, @buildOptions()

      insert: (obj, cb) ->
        id = obj.getId()
        ids = @instance[@foreignKey] or []

        if @options.prepend
          ids.unshift id
        else
          ids.push id

        @instance.updateAttribute @foreignKey, ids, options
          .asCallback cb

      add: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @add data, {}, options

        if data instanceof @model
          return @insert null, data, cb

        filter = where: {}
        filter.where[@model.primaryKey] = data

        options.instance = @instance
        options.name = @as

        @model.findOne filter, options
          .then (instance) =>
            @insert instance
          .asCallback cb

      remove: (id, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @remove data, {}, options

        if id instanceof @model
          return @remove id.getId(), options, cb

        ids = @instance[@foreignKey] or []

        index = ids.findIndex (i) ->
          i is id

        if index is -1
          return cb()

        ids.splice index, 1

        options.instance = @instance
        options.name = @as

        @instance.updateAttribute @foreignKey, ids, options
          .asCallback cb
