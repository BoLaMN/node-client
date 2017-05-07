debug = require('debug')('filter:match')

module.exports = ->

  @factory 'Filter', (TypeOf, Eql, Ops) ->

    filter = (target = {}, query) ->
      ret = {}

      for key of query
        if not query.hasOwnProperty(key)
          continue

        val = query[key]
        keys = key.split('.')

        matches = []

        if key is '$and'
          i = 0
          j = val.length

          while i < j
            if not filter(target, val[i])
              return false
            i++
          i++
          continue

        if key is '$or'
          fullfilled = false

          i = 0
          j = val.length

          while i < j
            if filter(target, val[i])
              fullfilled = true
              break
            i++

          if not fullfilled
            return false

          i++
          continue

        if key is '$nor'
          i = 0
          j = val.length

          while i < j
            if filter(target, val[i])
              return false
            i++
          i++
          continue

        i = 0

        while i < keys.length
          target = target[keys[i]]

          switch TypeOf(target)
            when 'array'
              prefix = keys.slice(0, i + 1).join('.')
              search = keys.slice(i + 1).join('.')

              debug 'searching array "%s"', prefix

              if val.$size and not search.length
                return compare(val, target)

              subset = ret[prefix] or target

              ii = 0

              while ii < subset.length
                if search.length
                  q = {}
                  q[search] = val

                  if 'object' is TypeOf(subset[ii])
                    debug 'attempting subdoc search with query %j', q

                    if filter(subset[ii], q)
                      if not ret[prefix] or not  ~ret[prefix].indexOf(subset[ii])
                        matches.push subset[ii]
                else
                  debug 'performing simple array item search'

                  if compare(val, subset[ii])
                    if not ret[prefix] or not  ~ret[prefix].indexOf(subset[ii])
                      matches.push subset[ii]

                ii++

              if matches.length
                ret[prefix] = ret[prefix] or []
                ret[prefix].push.apply ret[prefix], matches
            when 'undefined'
              return false
            when 'object'
              if null isnt keys[i + 1]
                ii++
                continue
              else if not compare(val, target)
                return false
            else
              if not compare(val, target)
                return false

          i++

      ret

    ###*
    # Compares the given matcher with the document value.
    #
    # @param {Mixed} matcher
    # @param {Mixed} value
    # @api private
    ###

    compare = (matcher, val) ->
      if 'object' isnt TypeOf(matcher)
        return Eql(matcher, val)

      keys = Object.keys(matcher)

      if '$' is keys[0][0]
        i = 0

        while i < keys.length
          if '$elemMatch' is keys[i]
            return false isnt filter(val, matcher.$elemMatch)
          else
            if not Ops[keys[i]](matcher[keys[i]], val)
              return false

          i++

        true
      else
        Eql matcher, val

    filter
