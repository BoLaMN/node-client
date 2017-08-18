'use strict'

module.exports = ->

  @factory 'MemoryCollection', ->
    
    class MemoryCollection extends Array
      constructor: (key, prop, data = []) ->
        collection = []

        collection.__proto__ = @

        define = (prop, desc) ->
          Object.defineProperty collection, prop,
            writable: false
            enumerable: false
            value: desc

        define 'key', key
        define 'property', prop
        define 'sequence', 1
        define 'ids', []

        data.forEach (item) ->
          collection.push item

        return collection

      new: (arr = []) ->
        new @constructor @key, @property, arr

      concat: ->
        @new Array::concat.apply @, arguments
        
      filter: ->
        @new Array::filter.apply @, arguments

      remove: (id) ->
        idx = @ids.indexOf id[@key] or id

        if idx > -1
          @splice idx, 1

        idx > -1

      pop: ->
        removed = Array::pop.apply @, arguments
        @deindex removed
        removed

      push: (added) ->
        if not Array.isArray added
          added = [ added ]

        count = @length

        @build(added).forEach (add) =>
          @index add
          count = Array::push.apply @, [ add ]  

        count

      get: (id) ->
        @[@ids.indexOf(id)]

      has: (id) ->
        @ids.indexOf(id[@key] or id) > -1

      update: (obj, create = false) ->
        idx = @ids.indexOf obj[@key]

        if create and idx is -1
          return @push obj

        for own key, val of obj when val?
          if typeof val is 'function'
            continue

          @[idx][key] = val

        idx

      replace: (obj) ->
        idx = @ids.indexOf obj[@key]

        if idx is -1
          return false

        @[idx] = obj
        @[idx]

      index: (obj) ->
        if @ids.indexOf(obj[@key] or obj) > -1
          return

        @ids[@length] = obj[@key]

        @length

      deindex: (obj) ->
        idx = @ids.indexOf(obj[@key] or obj)

        if idx is -1
          return

        @ids.splice idx, 1
        @ids

      chunk: (size = 1) ->
        chunks = []
        i = 0

        while i < @length
          chunks.push @new @slice(i, i + size)
          i += size

        chunks

      shift: ->
        removed = Array::shift.apply @, arguments
        @deindex removed
        removed

      splice: (index, count, elements) ->
        args = [ index, count ]

        if elements
          if not Array.isArray elements
            elements = [ elements ]

          elements = @build elements

          args[3] = elements

        removed = Array::splice.apply @, args

        if elements
          elements.forEach (element) =>
            @index element  

        removed.forEach (element) =>
          @deindex element

        removed

      build: (arr) ->
        arr.filter (obj) => 
          if not obj[@key]
            obj[@key] = @property.type?() or @sequence++
            exists = false 
          else 
            exists = @has obj

          not exists

      unshift: (added) ->
        if not Array.isArray added
           added = [ added ]

        count = @length

        @build(added).forEach (add) =>
          @index add
          count = Array::unshift.apply @, [ add ]

        count
