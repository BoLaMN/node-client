'use strict'

module.exports = ->

  @factory 'TransientORM', (Connector) ->
    
    class TransientORM extends Connector

      exists: (model, id, callback) ->
        if not callback and 'function' == typeof id
          callback = id
          id = undefined

        @flush 'exists', false, callback

      find: (model, id, callback) ->
        if not callback and 'function' == typeof id
          callback = id
          id = undefined

        @flush 'find', null, callback

      all: (model, filter, callback) ->
        if not callback and 'function' == typeof filter
          callback = filter
          filter = undefined

        @flush 'all', [], callback

      count: (model, where, callback) ->
        if not callback and 'function' == typeof where
          callback = where
          where = undefined

        @flush 'count', 0, callback

      create: (model, data, callback) ->
        props = @_models[model].properties
        idName = @idName(model)

        if idName and props[idName]
          id = @getIdValue(model, data) or @generateId(model, data, idName)
          id = props[idName] and props[idName].type and props[idName].type(id) or id

          @setIdValue model, data, id

        @flush 'create', id, callback

      save: (model, data, callback) ->
        @flush 'save', data, callback

      update: TransientORM::updateAll

      updateAll: (model, where, data, cb) ->
        count = 0

        @flush 'update', { count }, cb

      updateAttributes: (model, id, data, cb) ->
        if !id
          err = new Error 'You must provide an id when updating attributes!'
        
          if cb
            return cb err
          else
            throw err
        
        @setIdValue model, data, id
        @save model, data, cb

      destroy: (model, id, callback) ->
        @flush 'destroy', null, callback

      destroyAll: (model, where, callback) ->
        if not callback and 'function' == typeof where
          callback = where
          where = undefined

        @flush 'destroyAll', null, callback

      flush: (action, result, callback = ->) ->
        process.nextTick ->
          callback null, result

      transaction: ->
        new Transient this

      exec: (callback) ->
        @onTransactionExec()

        setTimeout callback, 50
