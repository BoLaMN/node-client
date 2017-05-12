'use strict'

module.exports = ->

  @factory 'AbstractInclude', ->

    class AbstractInclude
      constructor: (@relation, @options, @subInclude, @objs) ->
        @filter = @objs.queryString
        @relation.applyScope null, @filter

      targetFetchHandler: (targets, objs = @objs) ->
        tasks = []

        if @subInclude and targets
          tasks.push =>
            @relation.to.include targets, @subInclude, @options

        tasks.push =>
          Promise.each objs, targets, @linkFn

        Promise.parallel tasks

      findIncludes: (model, filter, fkName, pageSize) ->
        foreignKeys = []

        if filter.where[fkName]
          foreignKeys = filter.where[fkName].inq
        else if filter.where.and
          for j of filter.where.and
            query = filter.where.and[j][fkName]

            if query and Array.isArray query.inq
              foreignKeys = query.inq
              break

        if not foreignKeys.length
          return Promise.resolve []

        if filter.limit or filter.skip or filter.offset
          pageSize = 1

        size = foreignKeys.length

        if size > inqLimit and pageSize <= 0
          pageSize = inqLimit

        if pageSize <= 0
          return model.find filter, @options

        listOfFKs = []

        i = 0

        while i < size
          end = i + pageSize

          if end > size
            end = size

          listOfFKs.push foreignKeys.slice(i, end)
          i += pageSize

        items = []

        listOfFKs = listOfFKs.filter (keys) ->
          keys.length > 0

        Promise.concat listOfFKs, (foreignKeys) =>
          filter.where[fkName] = inq: foreignKeys
          model.find filter, @options

      setData: (inst, data) ->
        if not inst
          return Promise.resolve()

        isInst = inst instanceof this

        if @relation.type is 'belongsTo'
          if inst[@relation.primaryKey] == null or inst[@relation.primaryKey] == undefined

            if isInst
              inst.__data[@relation.as] = null
            else
              inst[@relation.as] = null

            return Promise.resolve()

        if isInst
          if Array.isArray(data) and !(data instanceof List)
            data = new List(data, @relation.to)

          inst.__data[@relation.as] = data
          inst.setStrict false
        else
          inst[@relation.as] = data

        Promise.resolve data