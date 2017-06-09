module.exports = ->

  @relation 'BelongsTo', (Relation, Models) ->

    class BelongsTo extends Relation
      @belongs: true

      constructor: ->
        return super

      build: (data = {}) ->
        new @model data, @buildOptions()

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        model = @model

        if @discriminator
          modelToName = @instance[@discriminator]
          model = Models[modelToName]

        id = @instance[@foreignKey]

        options.instance = @instance
        options.name = @as

        model.findById(id, options)
          .then (data) =>
            @setAttributes data
          .asCallback cb
