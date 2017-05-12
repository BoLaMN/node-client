'use strict'


module.exports = ->

  @factory 'Inclusion', (isString, isPlainObject, isObject) ->

    processIncludeItem = (cls, objs, vals, targets) ->
      (include) ->
        relations = cls.relations

        if isObject include
          as = Object.keys(include)[0]
          sub = include[as]
        else
          as = include
          sub = []

        relation = relations[as]

        if not relation
          return Promise.reject new Error "Relation '#{ as }' is not defined for '#{ cls.modelName }' model"

        { primaryKey, foreignKey, through, to, multiple } = relation

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

        Promise.concat inqs, (inq) ->
          filter = where: {}
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

        if not include or Array.isArray(include) and not include.length or isPlainObject include and not Object.keys(include).length
          return Promise.resolve objects

        includes = processIncludeJoin include

        vals = {}
        targets = {}

        Promise.each includes, processIncludeItem @, objects, vals, targets
          .then -> objects