'use strict'

module.exports = ->

  @factory 'FilterWhere', (isObject, isPlainObject) ->

    getPropertyDefinition = (current, prop) ->
      split = prop.replace(/\.\d+/g, '').split '.'

      for key in split
        current = current.relations[key]?.to or current.attributes[key]

      current

    where = (conditions, model) ->
      query = {}

      if conditions is null or not isObject conditions
        return conditions

      for own k, cond of conditions

        if k in [ 'and', 'or', 'nor' ]
          if Array.isArray cond
            cond = cond.map (c) => where c, model

          query['$' + k] = cond

          return

        attr = getPropertyDefinition model, k

        parse = (c) ->
          return c unless attr 
          
          c.reduce (prev, x) ->
            b = attr.apply x
            prev.push b if b?
            prev
          , []

        if attr?.id
          k = '_id'

        query[k] ?= {}

        if cond is null
          query[k].$type = 10
        else if isPlainObject cond
          options = cond.options

          for own spec, c of cond
            if spec is 'between'
              query[k].$gte = c[0]
              query[k].$lte = c[1]
            else if spec is 'inq' and Array.isArray c
              query[k].$in = parse c
            else if spec is 'nin' and Array.isArray c
              query[k].$nin = parse c
            else if spec is 'like'
              query[k].$regex = new RegExp c, options
            else if spec is 'nlike'
              query[k].$not = new RegExp c, options
            else if spec is 'neq'
              query[k].$ne = c
            else if spec is 'regexp'
              query[k].$regex = c
            else

              if spec[0] isnt '$'
                spec = '$' + spec

              query[k][spec] = c
        else
          if attr
            cond = attr.apply cond

          query[k] = cond

    where