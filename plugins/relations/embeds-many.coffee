module.exports = ->

  @factory 'EmbedMany', (RelationArray, Where, Filter) ->

    class EmbedMany extends RelationArray
      @embedded: true

      @initialize: (@to, @from, params) ->
        super

        @

      constructor: (instance) ->
        return super

        @instance = instance

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        instance = @instance[@foreignKey]

        cb null, instance

        instance

      findById: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findById {}, options

        exists = @indexOf fkId

        if exists > -1
          item = @[exists]

        cb null, item

        item

      exists: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @exists {}, options

        @findById fkId, options
          .then (data) ->
            not not data
          .asCallback cb

      updateById: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateById fkId, data, {}, options

        if typeof data is 'function'
          return @updateById fkId, {}, data

        instance = @findById fkId
        instance.setAttributes data

        if not instance.isValid()
          return cb new ValidationError(instance)

        @instance.save().asCallback cb

      destroyById: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroyById fkId, {}, options

        instance = @findById fkId
        list = @instance[@as]

        index = list.indexOf instance

        if index is -1
          return cb()

        list.splice index, 1

        @instance.updateAttribute @as, list
          .asCallback cb

      destroyAll: (conditions, options = {}, cb = ->) ->
        list = @instance[@as]

        if not list
          return cb()

        if conditions and Object.keys(conditions).length > 0
          query = new Where conditions

          reject = (v) ->
            not Filter v, query

          list = list.filter reject

        @instance.updateAttribute @as, list
          .asCallback cb

      get: EmbedMany::findById
      set: EmbedMany::updateById
      unset: EmbedMany::destroyById

      at: (index, cb = ->) ->
        cb null, @[index]

        @[index]

      create: (data = {}, options = {}, cb = ->) ->
        instance = @build data

        if not instance.isValid()
          return done new ValidationError instance

        if @instance.isNewRecord()
          @instance.save().asCallback cb
        else
          @instance.updateAttribute @foreignKey, instance, options
            .asCallback cb

      build: (data) ->
        inst = new @to data, @buildOptions()

        if @options.prepend
          @unshift inst
        else
          @push inst

        inst

      add: (instance, data = {}, options = {}, cb = ->) ->
        belongsTo = @to.relations[options.belongsTo]

        if not belongsTo
          throw new Error('Invalid reference: ' + options.belongsTo or '(none)')

        fk2 = belongsTo.foreignKey
        pk2 = belongsTo.primaryKey

        inst = @build data

        query = {}
        query[fk2] = if instance instanceof belongsTo then instance[pk2] else instance

        belongsTo.findOne { where: query }, options
          .then (ref) =>
            if ref instanceof belongsTo
              inst[options.belongsTo] ref
              @instance.save
          .asCallback cb

      remove: (instance, options = {}, cb = ->) ->

        @instance[definition.name] query, options
          .then (items) =>
            items.forEach (item) =>
              @unset item
            @instance.save options
          .asCallback cb