RelationArray = require './relation-array'

class HasMany extends RelationArray

  @initialize: (@from, @to, params) ->
    super

    @

  constructor: (@instance) ->
    super

  build: (data = {}) ->
    data[@foreignKey] = @instance[@primaryKey]

    new @to data, @buildOptions()

  findById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findById fkId, {}, options

    if not @foreignKey
      return cb

    exists = @indexOf fkId

    if exists > -1
      item = @[exists]

      cb null, item

      Promise.resolve item
    else
      options.instance = @instance
      options.name = @as

      query = @query()
      query.where[@to.primaryKey] = fkId

      @to.findOne query, options, cb
        .then (res) =>
          @push res
          res

  exists: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @exists fkId, {}, options

    @findById fkId, options, cb

  create: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @create data, {}, options

    if typeof data is 'function'
      return @create {}, {}, data

    fkAndProps = (item) =>
      item[@foreignKey] = @instance[@primaryKey]

    if Array.isArray data
      data.forEach fkAndProps
    else
      fkAndProps data

    options.instance = @instance
    options.name = @as

    @to.create data, options, cb
      .then (res) =>
        @push res
        res

  query: (query = {}) ->
    query.where ?= {}
    query.where[@foreignKey] = @instance[@primaryKey]
    query

  get: (query, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @get query, {}, options

    if typeof query is 'function'
      return @get {}, {}, query

    options.instance = @instance
    options.name = @as

    @to.find @query(query), options, cb
      .then (res) =>
        @push res
        res

  updateById: (fkId, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @updateById data, {}, options

    if typeof data is 'function'
      return @updateById {}, {}, data

    @findById fkId, options, (err, inst) ->
      if err
        cb err

      inst.updateAttributes data, options, cb

  destroy: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroy fkId, {}, options

    @findById fkId, options
      .then (inst) =>
        index = @indexOf inst

        if index > -1
          @splice index, 1

        inst.destroy options

module.exports = HasMany