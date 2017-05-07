module.exports = ->

  @factory 'HasManyThrough', (HasMany) ->

    class HasManyThrough extends HasMany
      constructor: (@instance) ->
        super

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

        @exists fkId, options
          .then (exists) =>
            if not exists
              return Promise.reject()
            @to.findById fkId, options
          .asCallback cb

      destroyById: (fkId, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroyById fkId, {}, options

        @exists fkId, option
          .then (exists) =>
            if not exists
              return Promise.reject()
            @remove fkId, options
          .then ->
            @to.deleteById fkId, options
          .asCallback cb

      create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        if typeof data is 'function'
          return @create {}, {}, data

        options.instance = @instance
        options.name = @as

      createRelation = (instance, [ fk1, fk2 ]) =>
        object = {}
        where  = {}

        pk2 = @to.primaryKey

        object[fk1] = where[fk1] = @instance[@primaryKey]
        object[fk2] = where[fk2] = instance[pk2]

        query = where: where

        @through.findOrCreate query, object, options

      parent = undefined

      @to.create data, options
        .then (parent) =>
          keys = @throughKeys()
          if Array.isArray parent
            Promise.all parent.map (value) ->
              createRelation value, keys
          else
            createRelation parent, keys
        .catch (err) ->
          if parent
            parent.destroy options
          err
        .asCallback cb

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
        options.name = @as

        @through.findOrCreate query, data, options
          .asCallback cb

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
        options.name = @as

        @through.count query, options
          .asCallback cb

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
        options.name = @as

        @through.deleteAll query, options
          .asCallback cb
