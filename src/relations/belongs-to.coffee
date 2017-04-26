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

    @to.create data, options, (err, instance) =>
      if err
        return cb err

      @instance[@foreignKey] = instance[@primaryKey]

      if @instance.$isNew
        return cb err, instance

      @instance.save options, (err, inst) ->
        cb err, instance

  get: (options = {}, cb = ->) ->
    if typeof options is 'function'
      return @get {}, options

    to = @to

    if @discriminator
      modelToName = @instance[@discriminator]
      to = @from.models[modelToName]

    if not @primaryKey
      return cb()

    id = @instance[@foreignKey]

    options.instance = @instance
    options.name = @as

    to.findById id, options, cb

  update: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @update data, {}, options

    @get options, (err, instance) =>
      if err
        return cb err

      delete data[@primaryKey]

      instance.updateAttributes data, options, cb

  destroy: (options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroy {}, options

    @get options, (err, targetModel) =>
      if err
        return cb err

      @instance[@foreignKey] = null
      @instance.save options, cb

module.exports = BelongsTo