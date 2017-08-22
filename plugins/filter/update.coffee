
module.exports = ->

  @factory 'FilterUpdate', (debug) ->
    (data, doc) ->

      compare = (a, b) ->

        isDate = (obj) ->
          Object::toString.call(obj) is '[object Date]'

        equals = (a, b) ->
          if a is b
            return 0

          if typeof a == typeof b
            if a > b
              return 1

            if a < b
              return -1

          return

        array = (a, b) ->
          i = 0

          while i < Math.min(a.length, b.length)
            comp = compare(a[i], b[i])

            if comp != 0
              return comp

            i += 1

          equals a.length, b.length

        primitives = [ 'null', 'undefined', 'string', 'number', 'boolean' ]

        if typeof a in primitives
          return if typeof b in primitives then equals(a, b) else -1
        if typeof b in primitives
          return if typeof a in primitives then equals(a, b) else 1

        if isDate(a)
          return if isDate(b) then equals(a.getTime(), b.getTime()) else -1
        if isDate(b)
          return if isDate(a) then equals(a.getTime(), b.getTime()) else 1

        if Array.isArray(a)
          return if Array.isArray(b) then arrays(a, b) else -1
        if Array.isArray(b)
          return if Array.isArray(a) then arrays(a, b) else 1

        aKeys = Object.keys(a).sort()
        bKeys = Object.keys(b).sort()

        i = 0

        while i < Math.min(aKeys.length, bKeys.length)
          comp = compare(a[aKeys[i]], b[bKeys[i]])

          if comp != 0
            return comp

          i += 1

        equals aKeys.length, bKeys.length

      ops =

        $set: (obj, field, value) ->
          obj[field] = value
          return

        $unset: (obj, field, value) ->
          delete obj[field]
          return

        $push: (obj, field, value) ->
          if not obj.hasOwnProperty field
            obj[field] = []

          if not Array.isArray obj[field]
            throw new Error 'Can\'t $push an element on non-array values'

          if value isnt null and typeof value is 'object'
            if value.$slice and value.$each is undefined
              value.$each = []
          else
            if not value.$each
              return obj[field].push value

          keys = Object.keys value

          if keys.length >= 3 or keys.length is 2 and value.$slice is undefined
            throw new Error 'only use $slice with $each when $push to array'

          if not Array.isArray value.$each
            throw new Error '$each requires an array value'

          value.$each.forEach (v) ->
            obj[field].push v

          if value.$slice is undefined or typeof value.$slice isnt 'number'
            return

          if value.$slice is 0
            obj[field] = []
          else
            n = obj[field].length

            if value.$slice < 0
              start = Math.max 0, n + value.$slice
              end = n
            else if value.$slice > 0
              start = 0
              end = Math.min n, value.$slice

            obj[field] = obj[field].slice start, end

          return

        $addToSet: (obj, field, value) ->
          addToSet = true

          if not obj.hasOwnProperty field
            obj[field] = []

          if not Array.isArray obj[field]
            throw new Error 'Can\'t $addToSet an element on non-array values'

          if value isnt null and typeof value is 'object' and value.$each
            if Object.keys(value).length > 1
              throw new Error 'Can\'t use another field in conjunction with $each'

            if not Array.isArray value.$each
              throw new Error '$each requires an array value'

            value.$each.forEach (v) =>
              @$addToSet obj, field, v
              return
          else
            obj[field].forEach (v) ->
              if compare(v, value) is 0
                addToSet = false

            if addToSet
              obj[field].push value

          return

        $pop: (obj, field, value) ->
          if not Array.isArray obj[field]
            throw new Error '$pop on element from non-array values'

          if typeof value isnt 'number'
            throw new Error value + ' isnt an integer, cant use with $pop'

          if value is 0
            return

          if value > 0
            obj[field] = obj[field].slice 0, obj[field].length - 1
          else
            obj[field] = obj[field].slice 1

          return

        $pull: (obj, field, value) ->
          if not Array.isArray obj[field]
            throw new Error '$pull on element from non-array values'

          arr = obj[field]
          i = arr.length - 1

          while i >= 0
            if @matches arr[i], value
              arr.splice i, 1
            i -= 1

          return

        $inc: (obj, field, value) ->
          if typeof value isnt 'number'
            throw new Error value + ' must be a number'

          if typeof obj[field] isnt 'number'
            if not obj[field]
              obj[field] = value
            else
              throw new Error '$inc modifier on non-number fields'
          else
            obj[field] += value

          return

        $max: (obj, field, value) ->
          if typeof obj[field] is 'undefined'
            obj[field] = value
          else if value > obj[field]
            obj[field] = value

          return

        $min: (obj, field, value) ->
          if typeof obj[field] is 'undefined'
            obj[field] = value
          else if value < obj[field]
            obj[field] = value

          return

      modify = (obj, field, value) ->
        parts = if typeof field is 'string' then field.split('.') else field

        if parts.length is 1
          return (m) =>
            modder = ops[m].bind this
            modder obj, field, value

        (m) =>
          if obj[parts[0]] is undefined
            if m is '$unset'
              return

            obj[parts[0]] = {}

          modder = ops[m].bind this
          modder obj[parts[0]], parts.slice(1), value

      mods = Object.keys data

      forceSet = mods.filter (mod) ->
        mod[0] is '$'

      if not forceSet.length
        keys = Object.keys data

        keys.forEach (k) ->
          modify(doc, k, data[k]) '$set'
      else
        mods.forEach (modifier) ->
          if not ops[modifier]
            throw new Error 'Unknown modifier ' + modifier

          if typeof data[modifier] isnt 'object'
            throw new Error 'Modifier ' + modifier + '\'s argument must be an object'

          keys = Object.keys data[modifier]

          keys.forEach (k) ->
            modify(doc, k, data[modifier][k]) modifier

      doc
