module.exports = ->

  @factory 'EmbedsOne', (Relation) ->

    class EmbedsOne extends Relation
      @embedded: true

      @initialize: (@to, @from, params) ->
        super

        @

      constructor: (@instance) ->
        super

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        instance = @instance[@foreignKey]

        cb null, instance

        instance

      build: (data = {}) ->
        new @to data, @buildOptions()

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        instance = @build data

        if not instance.isValid()
          return cb new ValidationError instance

        if @instance.isNewRecord()
          @instance.setAttribute @foreignKey, instance

          @instance.save().asCallback cb
        else
          @instance.updateAttribute @foreignKey, instance, options
            .asCallback cb

      update: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @update data, {}, options

        instance = @instance[@foreignKey]

        if not instance
          return @create data, options
            .asCallback cb

        instance.setAttributes data

        if not instance.isValid()
          return cb new ValidationError(instance)

        @instance.save().asCallback cb

      destroy: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy {}, options

        instance = @instance[@foreignKey]

        if not instance
          cb()
          return Promise.reject()

        @instance.unsetAttribute @foreignKey, true
        @instance.save().asCallback cb
