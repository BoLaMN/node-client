debug = require('debug')('filter:mods')

module.exports = ->

  @factory 'Modifiers', (TypeOf, Dot, Eql) ->

    ###*
    # Helper for determining if an array has the given value.
    #
    # @param {Array} array
    # @param {Object} value to check
    # @return {Boolean}
    ###

    has = (array, val) ->
      i = 0
      l = array.length

      while i < l
        if Eql(val, array[i])
          return true
        i++

      false

    ###*
    # Array#filter function generator for `$pull`/`$pullAll` operations.
    #
    # @param {Array} array of values to match
    # @param {Array} array to populate with results
    # @return {Function} that splices the array
    ###

    pull = (arr, vals, pulled) ->
      indexes = []

      a = 0

      while a < arr.length
        val = arr[a]
        i = 0

        while i < vals.length
          matcher = vals[i]

          if 'object' is TypeOf(matcher)
            if 'object' is TypeOf(val)
              match = false

              if Object.keys(matcher).length
                for i of matcher
                  if matcher.hasOwnProperty(i)
                    if Eql(matcher[i], val[i])
                      match = true
                    else
                      match = false
                      break
              else if not Object.keys(val).length
                match = true

              if match
                indexes.push a
                pulled.push val

                i++
                continue
            else
              debug 'ignoring pull match against object'
          else
            if Eql(matcher, val)
              indexes.push a
              pulled.push val

              i++
              continue
          i++
        a++

      ->
        i = 0

        while i < indexes.length
          index = indexes[i]
          arr.splice index - i, 1

          i++

    ###*
    # Helper to determine if a value is numeric.
    #
    # @param {String|Number} value
    # @return {Boolean} true if numeric
    # @api private
    ###

    numeric = (val) ->
      'number' is TypeOf(val) or Number(val) is val

    ###*
    # Performs a `$set`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {String} value to set
    # @return {Function} transaction (unless noop)
    ###

    $set: (obj, path, val) ->
      key = path.split('.').pop()
      obj = Dot.parent(obj, path, true)

      switch TypeOf(obj)
        when 'object'
          if not Eql(obj[key], val)
            return ->
              obj[key] = val
              val

        when 'array'
          if numeric(key)
            if not Eql(obj[key], val)
              return ->
                obj[key] = val
                val
          else
            throw new Error('can\'t append to array using string field name [' + key + ']')
        else
          throw new Error('$set only supports object not ' + TypeOf(obj))

      return

    ###*
    # Performs an `$unset`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {String} value to set
    # @return {Function} transaction (unless noop)
    ###

    $unset: (obj, path) ->
      key = path.split('.').pop()
      obj = Dot.parent(obj, path)

      switch TypeOf(obj)
        when 'array', 'object'
          if obj.hasOwnProperty(key)
            -> delete obj[key]
        else
          debug 'ignoring unset of inexisting key'

      return

    ###*
    # Performs a `$rename`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {String} value to set
    # @return {Function} transaction (unless noop)
    ###

    $rename: (obj, path, newKey) ->
      # target = source
      if path is newKey
        throw new Error('$rename source must differ from target')

      # target is parent of source
      if 0 is path.indexOf(newKey + '.')
        throw new Error('$rename target may not be a parent of source')

      p = Dot.parent(obj, path)
      t = TypeOf(p)

      if 'object' is t
        key = path.split('.').pop()

        if p.hasOwnProperty(key)
          return ->
            val = p[key]
            delete p[key]

            # target does initialize the path
            newp = Dot.parent(obj, newKey, true)

            # and also fails silently upon TypeOf mismatch
            if 'object' is TypeOf(newp)
              newp[newKey.split('.').pop()] = val
            else
              debug 'invalid $rename target path TypeOf'

            # returns the name of the new key
            newKey
        else
          debug 'ignoring rename from inexisting source'
      else if 'undefined' isnt t
        throw new Error('$rename source field invalid')

      return

    ###*
    # Performs an `$inc`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {String} value to set
    # @return {Function} transaction (unless noop)
    ###

    $inc: (obj, path, inc) ->
      if 'number' isnt TypeOf(inc)
        throw new Error('Modifier $inc allowed for numbers only')

      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      switch TypeOf(obj)
        when 'array', 'object'
          if obj.hasOwnProperty(key)
            if 'number' isnt TypeOf(obj[key])
              throw new Error('Cannot apply $inc modifier to non-number')
            return ->
              obj[key] += inc
              inc
          else if 'object' is TypeOf(obj) or numeric(key)
            return ->
              obj[key] = inc
              inc
          else
            throw new Error('can\'t append to array using string field name [' + key + ']')
        else
          throw new Error('Cannot apply $inc modifier to non-number')

      return

    ###*
    # Performs an `$pop`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {String} value to set
    # @return {Function} transaction (unless noop)
    ###

    $pop: (obj, path, val) ->
      obj = Dot.parent(obj, path)
      key = path.split('.').pop()

      switch TypeOf(obj)
        when 'array', 'object'
          if obj.hasOwnProperty(key)
            switch TypeOf(obj[key])
              when 'array'
                if obj[key].length
                  return ->
                    if -1 is val
                      obj[key].shift()
                    else
                      obj[key].pop()
              when 'undefined'
                debug 'ignoring pop to inexisting key'
              else
                throw new Error('Cannot apply $pop modifier to non-array')
          else
            debug 'ignoring pop to inexisting key'
        when 'undefined'
          debug 'ignoring pop to inexisting key'

      return

    ###*
    # Performs a `$push`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {Object} value to push
    # @return {Function} transaction (unless noop)
    ###

    $push: (obj, path, val) ->
      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      switch TypeOf(obj)
        when 'object'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              return ->
                obj[key].push val
                val
            else
              throw new Error('Cannot apply $push/$pushAll modifier to non-array')
          else
            return ->
              obj[key] = [ val ]
              val
        when 'array'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              return ->
                obj[key].push val
                val
            else
              throw new Error('Cannot apply $push/$pushAll modifier to non-array')
          else if numeric(key)
            return ->
              obj[key] = [ val ]
              val
          else
            throw new Error('can\'t append to array using string field name [' + key + ']')

      return

    ###*
    # Performs a `$pushAll`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {Array} values to push
    # @return {Function} transaction (unless noop)
    ###

    $pushAll: (obj, path, val) ->
      if 'array' isnt TypeOf(val)
        throw new Error('Modifier $pushAll/pullAll allowed for arrays only')

      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      switch TypeOf(obj)
        when 'object'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              return ->
                obj[key].push.apply obj[key], val
                val
            else
              throw new Error('Cannot apply $push/$pushAll modifier to non-array')
          else
            return ->
              obj[key] = val
              val
        when 'array'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              return ->
                obj[key].push.apply obj[key], val
                val
            else
              throw new Error('Cannot apply $push/$pushAll modifier to non-array')
          else if numeric(key)
            return ->
              obj[key] = val
              val
          else
            throw new Error('can\'t append to array using string field name [' + key + ']')

      return

    ###*
    # Performs a `$pull`.
    ###

    $pull: (obj, path, val) ->
      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      t = TypeOf(obj)

      switch t
        when 'object'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              pulled = []
              splice = pull(obj[key], [ val ], pulled)

              if pulled.length
                return ->
                  splice()
                  pulled
            else
              throw new Error('Cannot apply $pull/$pullAll modifier to non-array')
        when 'array'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              pulled = []
              splice = pull(obj[key], [ val ], pulled)

              if pulled.length
                return ->
                  splice()
                  pulled
            else
              throw new Error('Cannot apply $pull/$pullAll modifier to non-array')
          else
            debug 'ignoring pull to non array'
        else
          if 'undefined' isnt t
            throw new Error('LEFT_SUBFIELD only supports Object: hello not: ' + t)

      return

    ###*
    # Performs a `$pullAll`.
    ###

    $pullAll: (obj, path, val) ->
      if 'array' isnt TypeOf(val)
        throw new Error('Modifier $pushAll/pullAll allowed for arrays only')

      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      t = TypeOf(obj)

      switch t
        when 'object'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              pulled = []
              splice = pull(obj[key], val, pulled)

              if pulled.length
                return ->
                  splice()
                  pulled
            else
              throw new Error('Cannot apply $pull/$pullAll modifier to non-array')
        when 'array'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              pulled = []
              splice = pull(obj[key], val, pulled)

              if pulled.length
                return ->
                  splice()
                  pulled
            else
              throw new Error('Cannot apply $pull/$pullAll modifier to non-array')
          else
            debug 'ignoring pull to non array'
        else
          if 'undefined' isnt t
            throw new Error('LEFT_SUBFIELD only supports Object: hello not: ' + t)

      return

    ###*
    # Performs a `$addToSet`.
    #
    # @param {Object} object to modify
    # @param {String} path to alter
    # @param {Object} value to push
    # @param {Boolean} internal, true if recursing
    # @return {Function} transaction (unless noop)
    ###

    $addToSet: (obj, path, val, recursing) ->
      if not recursing and 'array' is TypeOf(val.$each)
        fns = []

        i = 0
        l = val.$each.length

        while i < l
          fn = $addToSet(obj, path, val.$each[i], true)

          if fn
            fns.push fn

          i++

        if fns.length
          return ->
            values = []
            i = 0

            while i < fns.length
              values.push fns[i]()
              i++

            values
        else
          return

      obj = Dot.parent(obj, path, true)
      key = path.split('.').pop()

      switch TypeOf(obj)
        when 'object'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              if not has(obj[key], val)
                return ->
                  obj[key].push val
                  val
            else
              throw new Error('Cannot apply $addToSet modifier to non-array')
          else
            return ->
              obj[key] = [ val ]
              val
        when 'array'
          if obj.hasOwnProperty(key)
            if 'array' is TypeOf(obj[key])
              if not has(obj[key], val)
                return ->
                  obj[key].push val
                  val
            else
              throw new Error('Cannot apply $addToSet modifier to non-array')
          else if numeric(key)
            return ->
              obj[key] = [ val ]
              val
          else
            throw new Error('can\'t append to array using string field name [' + key + ']')

      return