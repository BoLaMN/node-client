'use strict'


module.exports = ->

  @factory 'Inclusion', (isString, KeyArray, isPlainObject, isObject, isEmpty) ->

    processIncludeItem = (cls, objs, ids, targets) ->
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

        { primaryKey, foreignKey, through, keyThrough, embedded, to, multiple, type } = relation

        finishIncludeItems = (included) ->
          for obj in included
            for objfrom in targets[primaryKey][obj[foreignKey]]
              if multiple
                if through
                  objfrom[as].push obj[keyThrough]
                else
                  objfrom[as].push obj
              else if through
                objfrom[as] = obj[keyThrough]
              else
                objfrom[as] = obj

          included

        inq = {}
        inqs = [ [] ]

        i = 0

        if embedded
          Promise.map(ids, (id) -> id[as]).then (included) ->
            to.include(included, sub).then finishIncludeItems
        else

          if type is 'referencesMany'
            for id in ids when id[foreignKey]?
              inqs[i] = inqs[i].concat id[foreignKey]
          else
            for id in ids[primaryKey] when id?
              if inqs[i].length >= 256
                i += 1

              if not inq[id]
                inq[id] = true

                inqs[i] ?= []
                inqs[i].push id

          if not inqs[0].length
            return Promise.resolve []

          if through
            klass = through
          else
            klass = to

          Promise.concat inqs, (inq) ->
            filter = where: where or {}
            filter.where[foreignKey] = inq: inq
            klass.find filter
          .then (included) ->
            arr = new KeyArray included, klass.primaryKey

            if through
              model.include(arr, klass).then finishIncludeItems
            else
              to.include(arr, sub).then finishIncludeItems

    class Inclusion

      @include: (objects, include) ->
        console.log 'object ids', objects.ids
        console.log 'object targets', objects.targets

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

        ids = objects.ids
        targets = objects.targets

        Promise.each includes, processIncludeItem @, objects, ids, targets
          .then -> objects