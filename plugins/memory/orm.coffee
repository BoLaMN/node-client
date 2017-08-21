'use strict'

module.exports = ->

  @factory 'MemoryORM', (Connector) ->
    
    class MemoryORM extends Connector
      constructor: (model) ->
        super

        @model = model

      create: (data, options, callback) ->
        id = data.getId()

        if @collection().has id
          return callback new Error 'Duplicate entry for ' + model + '.' + idName

        @collection().push data

        callback null, id

      collection: (data) ->
        @constructor.collection @model.name, data

      count: (where, options, callback) ->
        data = @collection()
        count = data.length 

        if where
          result = applyFilter data, where: where
          count = result.length 

        callback null, count 

      destroy: (id, options, callback) ->
        callback null, count: @collection().remove id 

      destroyAll: (where, options, callback) ->
        data = @collection()
        count = data.length

        if where
          result = applyFilter data, where: where
          @collection result
          count = count - result.length
        else
          @collection []

        callback null, count: count

      exists: (id, options, callback) ->
        callback null, @collection().has id

      all: (filter, options, callback) ->
        data = @collection()

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

      find: (id, options, callback) ->
        callback null, @collection().get id

      findOrCreate: (filter, data, callback) ->
        @all filter, {}, (err, [ data ]) =>
          if err or data
            return callback err, data, false 

          @create data, (err, id) ->
            callback err, data, true

      replaceById: (id, data, options, cb) ->
        if not id
          return cb new Error('You must provide an id when replacing!')

        if not @collection().has id
          return cb new Error 'Could not replace. Object with id ' + id + ' does not exist!'

        cb null, @collection().replace data

      replaceOrCreate: (data, options, callback) ->
        idName = @model.primaryKey
        id = data.getId()

        filter = where: {}
        filter.where[idName] = id

        @all filter, options, (err, [ data ]) =>
          if not data
            @create data, options, (err, id) ->
              callback err, data, isNewInstance: true
          else
            @collection().replace data

            callback err, data, isNewInstance: false

      save: (data, options, callback) ->
        exists = @collection().has data
        
        @collection().update data, true

        callback null, data, isNewInstance: not exists

      update: (where = {}, update, options, callback) ->
        data = @collection()

        results = applyFilter data, where: where

        results.forEach (item) =>
          id = @getIdValue item
          @updateAttributes id, data, options, done

        callback null, count: results.length

      updateAll: MemoryORM::update

      updateAttributes: (id, data, options, callback) ->
        if id
          @setIdValue data, id

          if @collection().has data
            return @save data, options, callback

        callback new Error('Could not update attributes. Object with id ' + id + ' does not exist!')

      updateOrCreate: (data, options, callback) ->
        exists = @collection().has data
        
        @collection().update data, true

        callback null, data, isNewInstance: not exists
