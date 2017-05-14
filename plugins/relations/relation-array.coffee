proto = Array.prototype

module.exports = ->

  @factory 'RelationArray', (Relation) ->

    class RelationArray extends Relation
      @multiple: true

      constructor: ->
        super

        return @injectMethods []

      injectMethods: (collection) ->

        define = (prop, desc) ->
          return if prop is 'constructor'

          Object.defineProperty collection, prop,
            writable: false
            enumerable: false
            value: desc

        methods = @methods.concat Object.getOwnPropertyNames @

        methods.forEach (method) =>
          define method, (@[method] or @[method])

        if not @__super__
          return collection

        for own key, value of @__super__
          define key, value

        path = [
          @instance.$path
          @as
        ]
          .filter (v) -> v
          .join '.'

        define '$path', path
        define '$indexes', []

        collection

      methods: [
        'instance', 'pop', 'push', 'shift', 'splice', 'index', 'deindex', 'indexOf'
        'unshift', 'reverse', 'sort', 'toJSON', 'toArray', 'buildOptions', 'has', 'build'
      ]

      build: (data = {}) ->
        if data instanceof @to
          for key, value of @buildOptions()
            data.$property '$' + key,
              value: value or null
          return data
        else
          new @to data, @buildOptions()

      deindex: (data) ->
        id = data.getId()

        if not id
          return

        idx = @$indexes.indexOf id

        if idx > -1
          @$indexes.splice idx, 1

        @$indexes

      has: (data) ->
        if not data
          return false

        exists = @indexOf data

        if exists > -1
          return true

        false

      index: (data) ->
        if not data instanceof @to
          data = @build data

        id = data.getId()

        if not id
          return

        if not @$indexes
          @property '$indexes', value: []

        idx = @$indexes.indexOf id

        if idx > -1
          return

        @$indexes.push id

        data

      indexOf: (a) ->
        a = a?.getId?() or
            a?[@to.primaryKey] or
            a

        a = a?.toString?() or a
        i = 0

        while i < @length
          b = @[i].getId?() or @[i]
          if a is (b?.toString?() or b)
            return i
          ++i

        -1

      pop: ->
        removed = proto.pop.apply @, arguments

        @deindex removed
        @instance.emit '$pull', @$path + '.' + (@length + 1), removed

        removed

      push: (args) ->

        if not Array.isArray args
          args = [ args ]

        added = args
          .filter (obj) =>
            @indexOf(obj) is -1
          .map @build.bind(@)

        count = @length

        added.forEach (add) =>
          count = proto.push.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          @instance.emit '$push', @$path + '.' + (count + i), added[i], i
          i++

        count

      shift: ->
        removed = proto.shift.apply @, arguments

        @deindex removed
        @instance.emit '$pull', @$path + '.0', removed, 0

        removed

      splice: (index, count, elements) ->
        args = [ index, count ]

        added = []

        if elements
          if not Array.isArray elements
            elements = [ elements ]

          added = elements
            .filter (obj) =>
              @indexOf(obj) > -1
            .map @build.bind(@)

          if added.length
            args.push added

        removed = proto.splice.apply @, args

        i = 0

        while i < removed.length
          @deindex removed[i]
          @instance.emit '$pull', removed[i], index
          i++

        i = 0

        while i < added.length
          @index added[i]
          @instance.emit '$push', added[i], index + i
          i++

        removed

      toObject: ->
        @map (obj) ->
          obj.toObject?() or obj
        .toArray()

      toJSON: ->
        @map (obj) ->
          obj.toJSON?() or obj
        .toArray()

      toArray: ->
        proto.slice.call @

      unshift: (args) ->
        if not Array.isArray args
          args = [ args ]

        added = args
          .filter (obj) =>
            @indexOf(obj) is -1
          .map @build.bind(@)

        count = @length

        added.forEach (add) =>
          count = proto.unshift.apply @, [ add ]

        i = 0

        while i < added.length
          @index added[i]
          @instance.emit '$push', @$path + '.' + (count + i), added[i], i
          i++

        count
