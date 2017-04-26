RelationArray = require './relation-array'

class ReferencesMany extends RelationArray
  @embedded: true

  @initialize: (@from, @to, params) ->
    super

    @

  constructor: (@instance) ->
    super

  get: (options = {}, cb = ->) ->
    if typeof options is 'function'
      return @get {}, options

    options.instance = @instance
    options.name = @as

    @to.findByIds @, options, cb

  findById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findById fkId, {}, cb

    id = @instance[@foreignKey] or []

    options.instance = @instance
    options.name = @as

    @to.findByIds [ fkId ], options, cb

  exists: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @exists fkId, {}, options

    exists = @indexOf fkId

    if exists > -1
      item = @[exists]

    cb null, item

    item

  updateById: (fkId, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @updateById data, {}, options

    if typeof data is 'function'
      return @updateById {}, {}, data

    @findById fkId, options, (err, inst) ->
      if err
        return cb err

      inst.updateAttributes data, options, cb

  destroyById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroyById fkId, {}, options

    @findById fkId, options, (err, inst) =>
      if err
        return cb err

      @remove inst, (err, ids) ->
        if err
          return cb err

        inst.destroy cb

  at: (index, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @at index, {}, options

    ids = @instance[@foreignKey] or []

    @findById ids[index], options, cb

  create: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @create data, {}, options

    if typeof data is 'function'
      return @create {}, {}, data

    inst = @build data

    options.instance = @instance
    options.name = @as

    inst.save options, (err, inst) =>
      @insert err, inst, cb

  build: (data = {}) ->
    new @to data, @buildOptions()

  insert: (err, obj, cb) ->
    if err or not obj
      return cb err

    id = obj[@primaryKey]
    ids = @instance[@foreignKey] or []

    if @options.prepend
      ids.unshift id
    else
      ids.push id

    @instance.updateAttribute @foreignKey, ids, options, cb

  add: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @add data, {}, options

    if data instanceof @to
      return @insert null, data, cb

    filter = where: {}
    filter.where[@primaryKey] = data

    options.instance = @instance
    options.name = @as

    @to.findOne filter, options, (err, inst) =>
      @insert err, inst, cb

  remove: (id, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @remove data, {}, options

    if id instanceof @to
      return @remove id[@primaryKey], options, cb

    ids = @instance[@foreignKey] or []

    index = ids.findIndex (i) ->
      i is id

    if index is -1
      return cb()

    ids.splice index, 1

    options.instance = @instance
    options.name = @as

    @instance.updateAttribute @foreignKey, ids, options, cb

module.exports = ReferencesMany