'use strict'


module.exports = ->

  @factory 'Inclusion', (isString, isPlainObject, isObject, isEmpty) ->

    processIncludeItem = (cls, objs, vals, targets) ->
      (filter) ->
        relations = cls.relations

        if isObject filter
          as = Object.keys(filter)[0]
          { where, sub } = filter[as]
        else
          as = filter
          sub = []

        relation = relations[as]

        if not relation
          return Promise.reject new Error "Relation '#{ as }' is not defined for '#{ cls.modelName }' model"

        { primaryKey, foreignKey, through, embedded, to, multiple, type } = relation

        finishIncludeItems = (included) ->
          for obj in included
            for objfrom in targets[primaryKey][obj[foreignKey]]
              if multiple
                if through
                  objfrom[as].push obj[through]
                else
                  objfrom[as].push obj
              else if through
                objfrom[as] = obj[through]
              else
                objfrom[as] = obj

          included

        if not vals[primaryKey]
          targets[primaryKey] = {}

          objs.filter(Boolean).forEach (obj) ->
            targets[primaryKey][obj[primaryKey]] ?= []
            targets[primaryKey][obj[primaryKey]].push obj

          vals[primaryKey] = Object.keys targets[primaryKey]

        inq = {}
        inqs = [ [] ]

        i = 0

        if not embedded

          if type is 'referencesMany'
            for val in vals when val[foreignKey]?
              inqs[i] = inqs[i].concat val[foreignKey]
          else
            for val in vals[primaryKey] when val?
              if inqs[i].length >= 256
                i += 1

              if not inq[val]
                inq[val] = true

                inqs[i] ?= []
                inqs[i].push val

          if not inqs[0].length
            return Promise.resolve []

          if through
            klass = through
          else
            klass = to

        else

          klass = find: ->
            Promise.map vals, (val) ->
              val[as]

        Promise.concat inqs, (inq) ->
          filter = where: where or {}
          filter.where[foreignKey] = inq: inq
          klass.find filter
        .then (included) ->
          if through
            model.include(included, klass).then finishIncludeItems
          else
            to.include(included, sub).then finishIncludeItems

    class Inclusion

      @include: (objects, include) ->

        processIncludeJoin = (ij) ->
          if isString ij
            ij = [ ij ]

          if isPlainObject ij
            newIj = []

            Object.keys(ij).forEach (key) ->
              obj = {}
              obj[key] = ij[key]
              newIj.push obj

            return newIj

          ij

        if isEmpty(include) or isEmpty objects
          return Promise.resolve objects

        includes = processIncludeJoin include

        vals = {}
        targets = {}

        Promise.each includes, processIncludeItem @, objects, vals, targets
          .then -> objects