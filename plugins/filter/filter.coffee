
module.exports = ->

  @factory 'FilterMatch', (debug, moment) ->

    type = (val) ->
      
      switch Object::toString.call val
        when '[object Function]'
          return 'function'
        when '[object Date]'
          return 'date'
        when '[object RegExp]'
          return 'regexp'
        when '[object Arguments]'
          return 'arguments'
        when '[object Array]'
          return 'array'
          
      if val is null
        return 'null'

      if val is undefined
        return 'undefined'

      if val is Object val
        return 'object'

      typeof val

    types =
      1: 'number'
      2: 'string'
      3: 'object'
      4: 'array'
      5: 'buffer'
      6: 'undefined'
      8: 'boolean'
      9: 'date'
      10: 'null'
      11: 'regexp'
      13: 'function'
      16: 'number'
      18: 'number'

    ops = 

      $ne: (matcher, val) ->
        not eql matcher, val

      $type: (matcher, val) ->
        type(matcher) is 'number' and 
        type(val) is types[matcher] 

      $between: ([ start, stop ], val) ->
        if ~[ null, undefined ].indexOf val 
          return false

        isDate = (value) ->
          isoformat = new RegExp [
            '^\\d{4}-\\d{2}-\\d{2}'        # Match YYYY-MM-DD
            '((T\\d{2}:\\d{2}(:\\d{2})?)'  # Match THH:mm:ss
            '(\\.\\d{1,6})?'               # Match .sssss
            '(Z|(\\+|-)\\d{2}:\\d{2})?)?$' # Time zone (Z or +hh:mm)
          ].join ''

          typeof value == 'string' and isoformat.test(value) and !isNaN(Date.parse(value))

        isTime = (value) ->
          timeformat = new RegExp /^(\d{2}:\d{2}(:\d{2})?)$/g # Match HH:mm:ss

          typeof value == 'string' and timeformat.test(value)

        if isTime(start) and isTime(stop)
          format = 'HH:mm:ss'

          if typeof val is 'string'
            parsed = moment(val).format format
          else
            parsed = val.format format

          a = moment parsed, format
          e = moment stop, format
          s = moment start, format

          debug 'found times', a, start, stop, a.isBetween s, e

          a.isBetween s, e
        else if isDate(start) and isDate(stop)
          if typeof val is 'string'
            a = moment val 
          else
            a = val 

          e = moment stop
          s = moment start

          debug 'found dates', a, start, stop, a.isBetween s, e

          a.isBetween s, e
        else
          a = if typeof val == 'number' then val else parseFloat(val)
          a >= start and val <= stop

      $gt: (matcher, val) ->
        type(matcher) is 'number' and 
        val > matcher

      $gte: (matcher, val) ->
        type(matcher) is 'number' and 
        val >= matcher

      $lt: (matcher, val) ->
        type(matcher) is 'number' and 
        val < matcher

      $lte: (matcher, val) ->
        type(matcher) is 'number' and 
        val <= matcher

      $elemMatch: (matcher, val) ->
        not filter val, matcher

      $regex: (matcher, val) ->
        if 'regexp' isnt type matcher
          matcher = new RegExp matcher
        matcher.test val

      $exists: (matcher, val) ->
        if matcher
          val isnt undefined
        else
          val is undefined

      $in: (matcher, val) ->
        if type(matcher) is val
          return false

        matcher.some (match) ->
          eql match, val

        false

      $nin: (matcher, val) ->
        not @$in matcher, val

      $size: (matcher, val) ->
        Array.isArray(val) and 
        matcher is val.length

    eql = (matcher, val) ->
      if not matcher?
        return val is null 
      
      if type(matcher) is 'regex'
        return matcher.test val

      if matcher?._bsontype and val?._bsontype
        if matcher.equals val
          return true

        matcher = matcher.getTimestamp().getTime()
        val = val.getTimestamp().getTime()

      if Array.isArray matcher
        if Array.isArray(val) and matcher.length is val.length
          matcher.every (match, i) -> eql val[i], match
        else
          false
      else if typeof matcher isnt 'object'
        matcher is val
      else
        keys = {}

        for own key, match of matcher
          if not eql match, val[key]
            return false

          keys[i] = true

        for own key of val
          if not keys[key]
            return false

        true

    compare = (matcher, val) ->
      if matcher isnt Object matcher
        return eql matcher, val

      keys = Object.keys matcher 
      first = keys[0]

      if not ops[first or '$' + first]
        return eql matcher, val

      for key in keys
        op = ops[key or '$' + key]
        return op matcher[key], val

      true

    filter = (obj = {}, query) ->

      check = (val) -> 
        filter obj, val

      for own key, val of query

        if key in [ '$and', 'and' ]
          return val.every check
        else if key in [ '$or', 'or' ]
          return val.some check
        else if key in [ '$nor', 'nor' ]
          return not val.some check
        
        target = obj
        parts = key.split '.' 

        for part, i in parts
          target = target[part]

          if target is undefined
            return false
          else if Array.isArray target
            prefix = parts.slice(0, i + 1).join '.'
            search = parts.slice(i + 1).join '.'

            if val.$size and not search.length
              return compare val, target
     
            matches = target.filter (subkey) ->
              if not search.length and compare val, subkey
                k = subkey
              else if subkey is Object subkey
                k = subkey if filter subkey, "#{search}": val
              not target or not ~target.indexOf k
            return matches.length > 0
          else if typeof target is 'object' 
            if parts[i + 1]
              continue
            else 
              return compare val, target
          else 
            return compare val, target

      false

    filter