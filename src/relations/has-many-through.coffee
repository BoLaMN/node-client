HasMany = require './has-many'

class HasManyThrough extends HasMany
  constructor: (instance) ->
    super

    @instance = instance

  throughKeys: (definition) ->
    pk2 = @to.primaryKey

    if typeof @polymorphic == 'object'
      fk1 = @foreignKey

      if @polymorphic.invert
        fk2 = @polymorphic.foreignKey
      else
        fk2 = @keyThrough
    else if @from is @to
      return findBelongsTo(@through, @to, pk2).sort (fk1, fk2) ->
        if @foreignKey == fk1 then -1 else 1
    else
      fk1 = findBelongsTo(@through, @from, @primaryKey)[0]
      fk2 = findBelongsTo(@through, @to, pk2)[0]

    [ fk1, fk2 ]

  findById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @findById fkId, {}, options

    @exists fkId, options, (err, exists) ->
      if err or not exists
        return cb err

      @to.findById fkId, options, cb

  destroyById: (fkId, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @destroyById fkId, {}, options

    @exists fkId, options, (err, exists) =>
      if err or not exists
        return cb err

      @remove fkId, options, (err) ->
        if err
          return cb err

        @to.deleteById fkId, options, cb

  create: (data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @create data, {}, options

    if typeof data is 'function'
      return @create {}, {}, data

    options.instance = @instance

    @to.create data, options, (err, to) =>
      if err
        return cb err

      createRelation = (to, next) ->
        object = {}
        where  = {}

        object[fk1] = where[fk1] = @instance[@primaryKey]
        object[fk2] = where[fk2] = to[pk2]

        query = where: where

        @applyProperties @instance, object
        @applyScope @instance, query

        @through.findOrCreate query, object, options, (err, through) ->
          if err
            return to.destroy options, (err) -> next err

          next err, to

      pk2 = @to.primaryKey

      [ fk1, fk2 ] = @throughKeys()

      if not Array.isArray to
        createRelation to, cb
      else
        async.map to, createRelation, cb

  add: (inst, data = {}, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @add data, {}, options

    if typeof data is 'function'
      return @add {}, {}, data

    pk2 = @to.primaryKey

    [ fk1, fk2 ] = @throughKeys()

    where = {}
    where[fk1] = data[fk1] = @instance[@primaryKey]
    where[fk2] = data[fk2] = if inst instanceof @to then inst[pk2] else inst

    query = where: where

    options.instance = @instance

    @through.findOrCreate query, data, options, cb

  exists: (inst, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @exists inst, {}, options

    if typeof inst is 'function'
      return @exists {}, {}, inst

    pk2 = @to.primaryKey

    [ fk1, fk2 ] = @throughKeys()

    where = {}
    where[fk1] = @instance[@primaryKey]
    where[fk2] = if inst instanceof @to then inst[pk2] else inst

    query = where: where

    options.instance = @instance

    @through.count query, options, cb

  remove: (inst, options = {}, cb = ->) ->
    if typeof options is 'function'
      return @remove {}, {}, inst

    pk2 = @to.primaryKey

    [ fk1, fk2 ] = @throughKeys()

    where = {}
    where[fk1] = @instance[@primaryKey]
    where[fk2] = if inst instanceof @to then inst[pk2] else inst

    query = where: where

    options.instance = @instance

    @through.deleteAll query, options, cb

  module.exports = HasManyThrough