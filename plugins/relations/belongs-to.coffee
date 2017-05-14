module.exports = ->

  @factory 'BelongsTo', (Relation, Models) ->

    class BelongsTo extends Relation
      @belongs: true

      @initialize: (@to, @from, params) ->
        super

        @

      constructor: ->
        return super

      build: (data = {}) ->
        new @to data, @buildOptions()

      get: (options = {}, cb = ->) ->
        if typeof options is 'function'
          return @get {}, options

        if not @primaryKey
          return cb()

        from = @from

        if @discriminator
          modelToName = @instance[@discriminator]
          from = Models[modelToName]

        id = @instance[@foreignKey]

        options.instance = @instance
        options.name = @as

        from.findById(id, options)
          .then (data) =>
            @setAttributes data
          .asCallback cb
