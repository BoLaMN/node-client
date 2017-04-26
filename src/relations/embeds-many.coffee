RelationArray = require './relation-array'

class EmbedsMany extends RelationArray
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

    @findById fkId, options, cb

  updateById: (fkId, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @updateById fkId, data, {}, options

    if typeof data is 'function'
      return @updateById fkId, {}, data

    instance = @findById fkId
    instance.setAttributes data

    if not instance.isValid()
      return cb new ValidationError(instance)

    @instance.save cb

  destroyById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroyById fkId, {}, options

    instance = @findById fkId
    list = @instance[@as]

    index = list.indexOf instance

    if index is -1
      return cb()

    list.splice index, 1

    @instance.updateAttribute @as, list, cb

  destroyAll: (where, options = {}, cb = ->) ->
    list = @instance[@as]

    if not list
      return cb()

    if where and Object.keys(where).length > 0
      filter = applyFilter where: where

      reject = (v) ->
        not filter v

      list = list.filter reject

    @instance.updateAttribute @as, list, cb

  get: EmbedsMany::findById
  set: EmbedsMany::updateById
  unset: EmbedsMany::destroyById

  at: (index, cb = ->) ->
    cb null, @[index]

    @[index]

  create: (data = {}, options = {}, cb = ->) ->
    instance = @build data

    if not instance.isValid()
      return done new ValidationError instance

    if @instance.isNewRecord()
      @instance.save cb
    else
      @instance.updateAttribute @foreignKey, instance, options, cb

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

    filter = where: query

    belongsTo.findOne filter, options, (err, ref) =>
      if ref instanceof belongsTo

        inst[options.belongsTo] ref

        @instance.save cb

  remove: (instance, options = {}, cb = ->) ->

    @instance[definition.name] filter, options, (err, items) ->
      if err
        return cb err

      items.forEach (item) =>
        @unset item

      @instance.save options, cb
