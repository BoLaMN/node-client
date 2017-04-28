Relation = require './relation'

class BelongsTo extends Relation
  @belongs: true

  @initialize: (@to, @from, params) ->
    super

    @

  constructor: (@instance) ->
    super

  build: (data = {}) ->
    new @to data, @buildOptions()

  create: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @create data, {}, options

    if typeof data is 'function'
      return @create {}, {}, data

    options.instance = @instance
    options.name = @as

    @to.create data, options
      .then (instance) =>
        @instance[@foreignKey] = instance[@primaryKey]

        if @instance.$isNew
          return instance

        @instance.save options
          .then => @instance
      .asCallback cb

  get: (options = {}, cb = ->) ->
    if typeof options is 'function'
      return @get {}, options

    if not @primaryKey
      return cb()

    to = @to

    if @discriminator
      modelToName = @instance[@discriminator]
      to = @from.models[modelToName]

    id = @instance[@foreignKey]

    options.instance = @instance
    options.name = @as

    to.findById(id, options).asCallback cb

  update: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @update data, {}, options

    @get(options).then (instance) =>
      delete data[@primaryKey]
      instance.updateAttributes data, options
    .asCallback cb

  destroy: (options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroy {}, options

    @get(options).then (instance) =>
      instance[@foreignKey] = null
      instance.save options
    .asCallback cb

module.exports = BelongsTo