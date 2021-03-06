module.exports = ->

  @relation 'EmbedMany', (RelationArray, FilterWhere, FilterMatch) ->

    class EmbedMany extends RelationArray
      @embedded: true

      constructor: ->
        return super

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        instance = @instance[@foreignKey]

        cb null, instance

        instance

      find: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @find {}, options

        exists = @indexOf fkId

        if exists > -1
          item = @[exists]

        cb null, item

        item

      exists: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @exists {}, options

        @find fkId, options
          .then (data) ->
            not not data
          .asCallback cb

      update: (fkId, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update fkId, data, {}, options

        if typeof data is 'function'
          return @update fkId, {}, data

        instance = @find fkId
        instance.setAttributes data

        if not instance.isValid()
          return cb new ValidationError(instance)

        @instance.save().asCallback cb

      destroy: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy fkId, {}, options

        instance = @find fkId
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
          filter = FilterWhere conditions, @

          reject = (v) ->
            not FilterMatch v, filter

          list = list.filter reject

        @instance.updateAttribute @as, list
          .asCallback cb

      get: EmbedMany::find
      set: EmbedMany::update
      unset: EmbedMany::destroy

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
        inst = new @model data, @buildOptions()

        if @options.prepend
          @unshift inst
        else
          @push inst

        inst

      add: (instance, data = {}, options = {}, cb = ->) ->
        belongsTo = @model.relations[options.belongsTo]

        if not belongsTo
          throw new Error('Invalid reference: ' + options.belongsTo or '(none)')

        fk2 = belongsTo.foreignKey
        pk2 = belongsTo.primaryKey

        inst = @build data

        filter = {}
        filter[fk2] = if instance instanceof belongsTo then instance[pk2] else instance

        belongsTo.findOne { where: filter }, options
          .then (ref) =>
            if ref instanceof belongsTo
              inst[options.belongsTo] ref
              @instance.save
          .asCallback cb

      remove: (instance, options = {}, cb = ->) ->

        @instance[definition.name] filter, options
          .then (items) =>
            items.forEach (item) =>
              @unset item
            @instance.save options
          .asCallback cb