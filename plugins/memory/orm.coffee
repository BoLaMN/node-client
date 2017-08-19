'use strict'

module.exports = ->

  @factory 'MemoryORM', (Connector) ->
    
    class MemoryORM extends Connector
      create: (model, data, options, callback) ->
        { properties } = @_models[model]
        
        idName = @idName model
        type = properties[idName]?.type

        id = @getIdValue model, data

        if type
          id = type(id) or id

        @setIdValue model, data, id

        if @collection(model).has id
          return callback new Error 'Duplicate entry for ' + model + '.' + idName

        @collection(model).push data

        callback null, id

      count: (model, where, options, callback) ->
        data = @collection(model)
        count = data.length 

        if where
          result = applyFilter data, where: where
          count = result.length 

        callback null, count 

      destroy: (model, id, options, callback) ->
        callback null, count: @collection(model).remove id 

      destroyAll: (model, where, options, callback) ->
        data = @collection model
        count = data.length

        if where
          result = applyFilter data, where: where
          @collection model, result
          count = count - result.length
        else
          @collection model, []

        callback null, count: count

      exists: (model, id, options, callback) ->
        callback null, @collection(model).has id

      all: (model, filter, options, callback) ->
        data = @collection model

        if not filter
          return data

        if not filter.order
          idNames = @idNames(model)

          if idNames and idNames.length
            filter.order = idNames.map (name) ->
              name + ' ASC' 

        results = applyFilter data, filter

        if results.length and filter?.include
          @_models[model].model.include results, filter.include, options, callback
        else
          callback null, results

      find: (model, id, options, callback) ->
        callback null, @collection(model).get id

      findOrCreate: (model, filter, data, callback) ->
        @all model, filter, {}, (err, [ data ]) =>
          if err or data
            return callback err, data, false 

          @create model, data, (err, id) ->
            callback err, data, true

      replaceById: (model, id, data, options, cb) ->
        if not id
          return cb new Error('You must provide an id when replacing!')

        @setIdValue model, data, id

        if not @collection(model).has id
          return cb new Error 'Could not replace. Object with id ' + id + ' does not exist!'

        cb null, @collection(model).replace data

      replaceOrCreate: (model, data, options, callback) ->
        idName = @idNames(model)[0]
        id = @getIdValue model, data

        filter = where: {}
        filter.where[idName] = id

        @all model, filter, {}, (err, [ data ]) =>
          if not data
            @create model, data, (err, id) ->
              callback err, data, isNewInstance: true
          else
            @collection(model).replace data

            callback err, data, isNewInstance: false

      save: (model, data, options, callback) ->
        exists = @collection(model).has data
        
        @collection(model).update data, true

        callback null, data, isNewInstance: not exists

      update: (model, where = {}, update, options, callback) ->
        data = @collection(model)

        results = applyFilter data, where: where

        results.forEach (item) =>
          id = @getIdValue model, item
          @updateAttributes model, id, data, options, done

        callback null, count: results.length

      updateAll: MemoryORM::update

      updateAttributes: (model, id, data, options, callback) ->
        if id
          @setIdValue model, data, id

          if @collection(model).has data
            return @save model, data, options, callback

        callback new Error('Could not update attributes. Object with id ' + id + ' does not exist!')

      updateOrCreate: (model, data, options, callback) ->
        exists = @collection(model).has data
        
        @collection(model).update data, true

        callback null, data, isNewInstance: not exists
