'use strict'

toFunction = require './ToFunction'

module.exports = ->

  @factory 'KeyArray', (Utils) ->
    { values } = Utils

    proto = Array.prototype

    class KeyArray
      constructor: (data = [], keys = []) ->
        collection = []

        if not Array.isArray keys
          keys = [ keys ]

        @injectClassMethods collection, keys

        data.forEach (item) ->
          collection.push item

        return collection

      injectClassMethods: (collection, keys) ->

        define = (prop, desc) ->
          Object.defineProperty collection, prop,
            writable: false
            enumerable: false
            value: desc

        for name, value of @
          define name, value

        define 'keys', keys
        define 'ids', {}
        define 'targets', {}

        collection

      concat: ->
        arr = proto.concat.apply @, arguments
        new @constructor arr, @keys

      filter: (predicate) ->
        fn = toFunction predicate
        arr = proto.filter.apply @, [ fn ]
        new @constructor arr, @keys

      pop: ->
        removed = proto.pop.apply @, arguments
        @deindex removed
        removed

      push: (added) ->
        if not Array.isArray added
          added = [ added ]

        count = @length

        added = added.filter (obj) =>
          not @has obj

        added.forEach (add) =>
          count = proto.push.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          i++

        count

      has: (obj) ->
        @keys.some (key) =>
          @ids[key]?.has obj[key]

      get: (fk, key) ->
        @[@ids[fk].get(key)]

      index: (obj) ->
        for key in @keys
          id = obj[key]

          return unless id

          if @ids[key]?.has id
            return @ids[key].get id

          @targets[key] ?= {}
          @targets[key][id] ?= new @constructor
          @targets[key][id].push obj

          @ids[key] ?= new Map()
          @ids[key].set id, @length - 1

      deindex: (obj) ->
        for key in @keys
          id = obj[key]

          return unless id

          if @ids[key]?.has id
            @ids[key].delete id

          return unless @targets[key]

          idx = @targets[key][id].indexOf obj

          if idx > -1
            @targets[key][id].slice idx, 1

        @ids

      chunk: (size) ->
        if size == null
          size = 1

        chunks = []
        i = 0

        while i < @length
          chunks.push new @constructor @slice(i, i + size), @keys
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
          not @has obj

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

        added = added.filter (obj) =>
          not @has obj

        added.forEach (add) =>
          count = proto.unshift.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          i++

        count
