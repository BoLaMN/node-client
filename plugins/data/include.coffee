'use strict'


module.exports = ->

  @factory 'Inclusion', (isString, KeyArray, isPlainObject, isObject, isEmpty) ->

    processIncludeItem = (cls, objs, ids, targets) ->
      (filter) ->
        { primaryKey, relations } = cls

        if isObject filter
          as = Object.keys(filter)[0]
          { where, sub } = filter[as]
        else
          as = filter
          sub = []

        relation = relations[as]

        if not relation
          return Promise.reject new Error "Relation '#{ as }' is not defined for '#{ cls.modelName }' model"

        { foreignKey, through, keyThrough, embedded, model, multiple, type } = relation

        setData = (obj, objfrom) ->
          if multiple
            if through
              objfrom[as].push obj[keyThrough]
            else
              objfrom[as].push obj
          else if through
            objfrom[as].setAttributes obj[keyThrough]
          else
            objfrom[as].setAttributes obj

        finishIncludeItems = (included) ->
          for obj in included
            if type in [ 'belongsTo', 'embedOne', 'embedMany' ]
              target = targets[foreignKey][obj[primaryKey]]
            else
              target = targets[primaryKey][obj[foreignKey]]

            for objfrom in target
              setData obj, objfrom

          included

        inq = {}
        inqs = [ [] ]

        i = 0

        if embedded
          Promise.map(objs, (obj) -> obj[as]).then (included) ->
            model.include(included, sub).then finishIncludeItems
        else if type is 'referencesMany'
            for id in ids when id[foreignKey]?
              inqs[i] = inqs[i].concat id[foreignKey]
        else

          if type is 'belongsTo'
            ds = ids[foreignKey]
          else
            ds = ids[primaryKey]

          ds.forEach (key, id) ->
            return unless id?

            if inqs[i].length >= 256
              i += 1

            if not inq[id]
              inq[id] = true

              inqs[i] ?= []
              inqs[i].push id

          if not inqs[0].length
            return Promise.resolve []

          if type is 'belongsTo'
            key = primaryKey
          else
            key = foreignKey

          Promise.concat inqs, (inq) ->
            filter = where: where or {}
            filter.where[key] = inq: inq
            (through or model).find filter
          .then (included) ->
            model.include(included, sub).then finishIncludeItems

    class Inclusion

      @include: (objects, include) ->
        if isEmpty(include) or isEmpty objects
          return Promise.resolve objects

        keys = []

        addKey = (key) =>
          value = @relations[key]

          return false unless value

          if value.polymorphic
            keys.push { key: value.foreignKey, discriminator: value.discriminator, }
          else if value.type is 'belongsTo'
            keys.push value.foreignKey

          keys.push @primaryKey

        processIncludeJoin = (ij) ->
          if isString ij
            ij = [ ij ] if addKey ij
          else if isPlainObject ij
            newIj = []

            Object.keys(ij).forEach (key) ->
              return unless addKey key

              obj = {}
              obj[key] = ij[key]

              newIj.push obj

            return newIj
          else
            ij.forEach addKey

          ij

        includes = processIncludeJoin include

        console.log 'keys', keys

        data = new KeyArray objects, keys

        ids = data.ids
        targets = data.targets

        Promise.each includes, processIncludeItem @, data, ids, targets
          .then -> data