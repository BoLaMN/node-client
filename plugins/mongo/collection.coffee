writeOpts =
  writeConcern: w: 1
  ordered: true

noop = ->

module.exports = ->

  @factory 'MongoCollection', (MongoCursor, utils, ObjectID) ->
    { extend } = utils

    class MongoCollection
      constructor: (@collection) ->

      aggregate: (pipeline, opts, cb) ->
        strm = new MongoCursor @collection.aggregate pipeline, opts

        if cb
          return strm.toArray().asCallback cb

        strm

      createIndex: (index, opts, cb) ->
        if typeof opts is 'function'
          return @createIndex index, {}, opts

        if not opts
          return @createIndex index, {}, noop

        if not cb
          return @createIndex index, opts, noop

        @collection.createIndex index, opts
          .asCallback cb

      count: (query, cb) ->
        if typeof query is 'function'
          return @count {}, query

        @find query
          .count()
          .asCallback cb

      distinct: (field, query, cb) ->
        params =
          key: field
          query: query

        @execute 'distinct', params
          .then (results) -> results.values
          .asCallback cb

      drop: (cb) ->
        @execute 'drop'
          .asCallback cb

      dropIndexes: (cb) ->
        @execute 'dropIndexes', index: '*'
          .asCallback cb

      dropIndex: (index, cb) ->
        @execute 'dropIndexes', index: index
          .asCallback cb

      execute: (cmd, opts, cb) ->
        if typeof opts is 'function'
          return @execute cmd, null, opts

        opts = opts or {}

        obj = {}
        obj[cmd] = @collection.s.name

        Object.keys(opts).forEach (key) ->
          obj[key] = opts[key]
          return

        @collection.s.db.command obj
          .asCallback cb

      ensureIndex: (index, opts, cb) ->
        if typeof opts is 'function'
          return @ensureIndex index, {}, opts

        if not opts
          return @ensureIndex index, {}, noop

        if not cb
          return @ensureIndex index, opts, noop

        @collection.ensureIndex(index, opts)
          .asCallback cb

      findIndexes: (cb) ->
        @collection.indexes()
          .asCallback cb

      find: (query, projection, opts, cb) ->
        if typeof query is 'function'
          return @find {}, null, null, query

        if typeof projection is 'function'
          return @find query, null, null, projection

        if typeof opts is 'function'
          return @find query, projection, null, opts

        cursor = new MongoCursor @collection.find(query, projection, opts)

        if cb
          return cursor.asCallback cb

        cursor

      findOne: (query, projection, cb) ->
        if typeof query is 'function'
          return @findOne {}, null, query

        if typeof projection is 'function'
          return @findOne query, null, projection

        @collection.findOne query, projection
          .asCallback cb

      findAndModify: (query, update, sort, opts, cb) ->
        if not opts and not cb
          return @findAndModify query, update, [], {}, noop

        if typeof sort is 'function'
          return @findAndModify query, update, [], {}, opts

        if typeof opts is 'function'
          return @findAndModify query, update, sort, {}, opts

        params =
          query: query
          update: update
          sort: sort

        @execute 'findAndModify', params, extend(writeOpts, opts)
          .then (results) ->
            [ results.value, results.lastErrorObject or n: 0 ]
          .asCallback cb, spread: true

      findOneAndUpdate: (query, data, opts, cb) ->
        if not opts and not cb
          return @findOneAndUpdate query, data, {}, noop

        if typeof opts is 'function'
          return @findOneAndUpdate query, data, {}, opts

        @execute 'findOneAndUpdate', query, data, opts
          .then (results) ->
            [ result.value, result.lastErrorObject or n: 0 ]
          .asCallback cb, spread: true

      group: (doc, cb) ->
        key = doc.key or doc.keyf

        @collection.group key, doc.cond, doc.initial, doc.reduce, doc.finalize
          .asCallback cb

      insert: (docs, opts, cb) ->
        if not opts and not cb
          return @insert docs, {}, noop

        if typeof opts is 'function'
          return @insert docs, {}, opts

        if opts and not cb
          return @insert docs, opts, noop

        ops = extend writeOpts, opts

        @collection.insert docs, ops
          .asCallback cb

      isCapped: (cb) ->
        @collection.isCapped()
          .asCallback cb

      mapReduce: (map, reduce, opts, cb) ->
        if typeof opts is 'function'
          return @mapReduce map, reduce, {}, opts

        if not cb
          return @mapReduce map, reduce, opts, noop

        @collection.mapReduce map, reduce, opts
          .asCallback cb

      reIndex: (cb) ->
        @execute 'reIndex'
          .asCallback cb

      remove: (query, opts, cb) ->
        if typeof query is 'function'
          return @remove {}, { justOne: false }, query

        if typeof opts is 'function'
          return @remove query, { justOne: false }, opts

        if typeof opts is 'boolean'
          return @remove query, { justOne: opts }, cb

        if not opts
          return @remove query, { justOne: false }, cb

        if not cb
          return @remove query, opts, noop

        deleteOperation = if opts.justOne then 'deleteOne' else 'deleteMany'

        @collection[deleteOperation] query, extend(opts, writeOpts)
          .then (results) -> results.result
          .asCallback cb

      rename: (name, opts, cb) ->
        if typeof opts is 'function'
          return @rename name, {}, opts

        if not opts
          return @rename name, {}, noop

        if not cb
          return @rename name, noop

        @collection.rename name, opts
          .asCallback cb

      save: (doc, opts, cb) ->
        if not opts and not cb
          return @save doc, {}, noop

        if typeof opts is 'function'
          return @save doc, {}, opts

        if not cb
          return @save doc, opts, noop

        if doc._id
          @update { _id: doc._id }, doc, extend({ upsert: true }, opts)
            .asCallback cb
        else
          @insert doc, opts
            .asCallback cb

      stats: (cb) ->
        @execute 'collStats'
          .asCallback cb

      toString: ->
        @collection.s.name

      update: (query, update, opts, cb) ->
        if not opts and not cb
          return @update query, update, {}, noop

        if typeof opts is 'function'
          return @update query, update, {}, opts

        @collection.update query, update, extend(writeOpts, opts)
          .then (results) -> results.result
          .asCallback cb
