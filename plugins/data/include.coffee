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
            delete processed[obj[foreignKey]]

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

        filter = where: {}

        if not vals[primaryKey]
          targets[primaryKey] = {}

          objs.filter(Boolean).forEach (obj) ->
            targets[primaryKey][obj[primaryKey]] ?= []
            targets[primaryKey][obj[primaryKey]].push obj

          vals[primaryKey] = Object.keys targets[primaryKey]

        processed = {}
        inq = []

        for val in vals[primaryKey]
          processed[val] = true

          if val?
            inq.push val

        if not inq.length
          return Promise.resolve []

        filter.where[foreignKey] = inq: inq

        if through
          through.find(filter).then (included) ->
            model.include(included, through).then finishIncludeItems
        else
          filter.include = sub
          to.find(filter).then finishIncludeItems

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