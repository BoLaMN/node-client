{ Readable } = require 'readable-stream'

module.exports = ->

  @factory 'MongoCursor', ->
    class MongoCursor extends Readable
      constructor: (cursor) ->
        super
          objectMode: true
          highWaterMark: 0

        @cursor = cursor

      next: (cb = ->) ->
        if @cursor.cursorState.dead or @cursor.cursorState.killed
          return cb null, null

        @cursor.next()
          .asCallback cb

      rewind: (cb = ->) ->
        @cursor.rewind cb
        this

      toArray: ->
        new Promise (resolve, reject) =>
          array = []

          iterate = =>
            @next (err, obj) ->
              if err
                return reject err
              if not obj
                return resolve array
              array.push obj
              iterate()

          iterate()

      mapArray: (mapfn, options) ->
        new Promise (resolve, reject) =>
          array = []

          iterate = =>
            @next (err, obj) ->
              if err
                return reject err
              if not obj?
                return resolve array
              if mapfn.constructor
                val = new mapfn obj, options
              else
                val = mapfn obj
              array.push val
              iterate()

          iterate()

      forEach: (fn) ->

        iterate = =>
          @next (err, obj) ->
            return fn err if err
            fn err, obj
            return if not obj
            iterate()

        iterate()

      count: (cb = ->) ->
        @cursor.count false, @opts
          .asCallback cb

      size: (cb = ->) ->
        @cursor.count true, @opts
          .asCallback cb

      explain: (cb = ->) ->
        @cursor.explain
          .asCallback cb

      destroy: (cb = ->) ->
        if not @cursor.close
          return cb()

        @cursor.close
          .asCallback cb

      _read: ->
        @next (err, data) =>
          if err
            return @emit 'error', err
          @push data

    [ 'batchSize'
      'hint'
      'limit'
      'maxTimeMS'
      'max'
      'min'
      'skip'
      'snapshot'
      'sort'
    ].forEach (opt) ->
      MongoCursor.prototype[opt] = (obj, cb = ->) ->
        @_opts[opt] = obj

        if cb
          return @toArray cb

        this

    MongoCursor