'use strict'

toFunction = require './ToFunction'

module.exports = ->

  @factory 'KeyArray', (Utils) ->
    { values } = Utils

    proto = Array.prototype

    class KeyArray
      constructor: (data, key) ->
        collection = []

        @injectClassMethods collection, key

        data.forEach (item) ->
          collection.push item

        return collection

      injectClassMethods: (collection, key) ->

        define = (prop, desc) ->
          Object.defineProperty collection, prop,
            writable: false
            enumerable: false
            value: desc

        for name, value of @
          define name, value

        define 'key', key
        define 'ids', new Map()

        collection

      concat: ->
        arr = proto.concat.apply @, arguments
        new @constructor arr, @key

      filter: (predicate) ->
        fn = toFunction predicate
        arr = proto.filter.apply @, [ fn ]
        new @constructor arr, @key

      pop: ->
        removed = proto.pop.apply @, arguments
        @deindex removed
        removed

      push: (added) ->
        if not Array.isArray added
          added = [ added ]

        count = @length

        added = added
          .filter (obj) =>
            not @ids.has obj[@key]
          .forEach (add) =>
            count = proto.push.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          i++

        count

      get: (key) ->
        @[@ids.get(key)]

      index: (obj) ->
        id = obj[@key]

        if @ids.has id
          return @ids.get id

        @ids.set id, @length - 1

      deindex: (obj) ->
        id = obj[@key]

        if @ids.has id
          @ids.delete id

        @ids

      chunk: (size) ->
        if size == null
          size = 1

        chunks = []
        i = 0

        while i < @length
          chunks.push new @constructor @slice(i, i + size), @key
          i += size

        chunks

      shift: ->
        removed = proto.shift.apply @, arguments
        @deindex removed
        removed

      splice: (index, count, added = []) ->
        args = [ index, count ]

        if not Array.isArray added
          added = [ added ]

        added = added.filter (obj) =>
          not @ids.has obj[@key]

        if added.length
          args.push added

        removed = proto.splice.apply @, args

        i = 0

        while i < removed.length
          @deindex removed[i]
          i++

        i = 0

        while i < added.length
          @index added[i]
          i++

        removed

      unshift: (added) ->
        if not Array.isArray added
           added = [ added ]

        count = @length

        added = added
          .filter (obj) =>
            not @ids.has obj[@key]
          .forEach (add) =>
            count = proto.unshift.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          i++

        count
