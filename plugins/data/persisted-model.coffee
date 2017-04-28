getArgs = require './utils/get-args'
assert = require './utils/assert'

Model = require './model'
ObjectProxy = require './utils/proxy'

class PersistedModel extends Model

  @create: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @create data, {}, options

    @execute 'create', data, options, cb

  @count: (where = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @count where, {}, options

    query = where: where

    @execute 'count', query, options, cb

  @destroy: (where = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroy where, {}, options

    query = where: where

    @execute 'destroy', query, options, cb

  @destroyById: (id, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroyById id, {}, options

    assert id, 'The id argument is required'

    @execute 'destroyById', id, options, cb

  @exists: (id, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @exists id, {}, options

    assert id, 'The id argument is required'

    query = where:
      id: id

    finish = (err, data) ->
      cb err, not not data

    @count query, options, finish

  @execute: (command, args...) ->
    argNames = getArgs @dao[command]

    ctx = {}

    for arg, idx in argNames
      ctx[arg] = args[idx]

    fns = [
      => @fire 'before ' + command, ctx
      => @dao[command].apply @dao, args
      (res) =>
        ctx.result = res
        @fire 'after ' + command, ctx
    ]

    current = Promise.resolve()

    promises = fns.map (fn, i) ->
      current = current.then (res) ->
        fn res
      current

    cb = ctx.cb or ->

    Promise.all promises
      .then -> ctx.result
      .asCallback cb

  @find: (query = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @find query, {}, options

    if typeof query is 'function'
      return @find {}, {}, query

    @execute 'find', query, options, cb

  @findOne: (where = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findOne where, {}, options

    query = where: where

    @execute 'findOne', query, options, cb

  @findById: (id, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findById id, {}, options

    assert id, 'The id argument is required'

    query = where:
      id: id

    @execute 'findOne', query, options, cb

  @findByIds: (ids = [], options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findByIds ids, {}, options

    assert ids.length, 'The ids argument is requires ids'

    query = where:
      id: inq: ids

    @find query, options, cb

  @update: (query = {}, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @updateAll query, data, {}, options

    @execute 'update', query, data, options, cb

  @updateById: (id, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @updateById id, data, {}, options

    assert id, 'The id argument is required'

    query = where:
      id: id

    @update query, data, options, cb

  constructor: (data = {}, options = {}) ->
    super

    @on '*', (event, path, value, id) =>
      @$events[event] ?= {}

      if event is '$index'
        @$events[event][path] ?= {}
        @$events[event][path][value] ?= []
        @$events[event][path][value].push id
      else
        @$events[event][path] = value

    proxy = new ObjectProxy @, @$path, @$parent

    @setAttributes data, proxy

    return proxy

  setAttributes: (data = {}, proxy = @) ->
    if data.id and @constructor.primaryKey isnt 'id'
      @setId data.id
      delete data.id

    if data._id
      @setId data._id
      delete data._id

    for key, value of data
      if typeof proxy[key] is 'function'
        continue if typeof value is 'function'
        proxy[key](value)
      else
        proxy[key] = value

    if @$parent and @$path and not @$loaded
      @$parent.emit '$loaded', @$path, @

    @

  execute: (command, args...) ->
    argNames = getArgs @constructor[command]

    options = argNames.indexOf 'options'

    if options > -1
      args[options - 1].instance = @

    data = argNames.indexOf 'data'

    if data > -1
      args.splice data - 1, 0, @

    if argNames[0] is 'id'
      args.unshift @getId()

    @constructor[command].apply @constructor, args

  create: (options = {}, cb = ->) ->
    @$isNew = false

    @execute 'create', options, cb

  destroy: (options = {}, cb = ->) ->
    @off()
    @execute 'destroyById', options, cb

  exists: (options = {}, cb = ->) ->
    @execute 'exists', options, cb

  save: (options = {}, cb = ->) ->
    if @$isNew
      action = 'create'
    else
      action = 'update'

    @[action] options, cb

  update: (options = {}, cb = ->) ->
    @execute 'updateById', options, cb

  updateAttributes: (data = {}, options = {}, cb = ->) ->
    @setAttributes data.toObject?() or data
    @save options, cb

  getId: ->
    @[@constructor.primaryKey]

  setId: (id) ->
    if not id
      delete @[@constructor.primaryKey]
    else
      @[@constructor.primaryKey] = id

    @

module.exports = PersistedModel